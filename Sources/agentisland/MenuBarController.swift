import SwiftUI
import AgentIslandCore
import AgentIslandAdapters
import AgentIslandLauncher
import AgentIslandTerminals

@Observable
@MainActor
final class MenuBarController {
    private(set) var pendingCount: Int = 0
    private(set) var pending: [PermissionRequest] = []
    private(set) var activeSessionsCount: Int = 0
    private(set) var lastEventAt: Date?
    private(set) var notices: [Notice] = []
    private(set) var sessionCards: [SessionCard] = []
    var prefs: AppPreferences {
        didSet { prefs.save(paths: paths) }
    }

    private let paths: Paths
    let queue: ApprovalQueue
    let sessions: ActiveSessions
    let history: HistoryWriter
    let noticeStore: NoticeStore
    let aggregator: SessionAggregator
    let router: EventRouter
    let server: SocketServer
    let installer: HookInstaller
    private let jumper = CompositeJumper.default()
    private var refreshTask: Task<Void, Never>?
    private(set) var panelController: PanelController!
    private(set) var soundPlayer: SoundPlayer!
    private(set) var hotkeyMonitor: HotkeyMonitor?
    private(set) var historyWindow: HistoryWindow?
    private(set) var onboarding: OnboardingWindow?
    private var lastPendingCount: Int = -1
    private var lastScreenID: ObjectIdentifier?
    private var lastNotificationAt: Date?
    var notchExpanded: Bool = false

    init() {
        let p = Paths()
        self.paths = p
        let loaded = AppPreferences.load(paths: p)
        self.prefs = loaded

        self.queue = ApprovalQueue(
            timeout: .seconds(loaded.requestTimeoutSeconds),
            dedupWindow: .seconds(loaded.dedupWindowSeconds)
        )
        self.sessions = ActiveSessions()
        self.history = HistoryWriter(url: p.historyJSONL)
        self.noticeStore = NoticeStore()
        self.aggregator = SessionAggregator()
        let adapter = ClaudeCodeAdapter()
        self.router = EventRouter(queue: queue, sessions: sessions,
                                  history: history, adapter: adapter,
                                  notices: noticeStore,
                                  aggregator: aggregator)
        self.server = SocketServer(router: router, paths: p)
        self.installer = HookInstaller(adapters: [adapter], paths: p)
        boot()
    }

    private func boot() {
        // Prompt for Accessibility on first launch — needed by
        // KeystrokeInjector to deliver synthesized keystrokes to terminals.
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let opts: CFDictionary = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)

        // Write lastrun JSON: cleanExit:false, flipped to true on graceful quit.
        try? paths.ensureAll()
        let lastrun: [String: Any] = [
            "startedAt": ISO8601DateFormatter().string(from: Date()),
            "cleanExit": false,
            "pid": Int(getpid())
        ]
        if let data = try? JSONSerialization.data(withJSONObject: lastrun, options: [.sortedKeys]) {
            try? data.write(to: paths.lastRun)
        }

        installer.installNow()
        let prefsRef = { [weak self] in self?.prefs.autoHealHooks ?? true }
        installer.startHealing(enabled: { @MainActor in prefsRef() })

        self.soundPlayer = SoundPlayer(paths: paths)
        self.panelController = PanelController(controller: self)

        let routerRef = self.router
        Task { [weak self] in
            await routerRef.setOnEventArrived { @Sendable event in
                Task { @MainActor in
                    self?.handleEventArrived(event)
                }
            }
        }

        do {
            try server.start()
        } catch {
            NSLog("agentisland: server start failed: \(error)")
        }

        panelController.updateForMode(prefs.displayMode)

        let onb = OnboardingWindow(controller: self, paths: paths)
        self.onboarding = onb
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            onb.showIfFirstRun()
        }

        if prefs.hotkeyEnabled {
            let mon = HotkeyMonitor { [weak self] in
                guard let self else { return }
                // Force panel to non-menubar mode briefly to show pending.
                self.panelController?.refresh()
                NSApp.activate(ignoringOtherApps: true)
            }
            mon.start()
            self.hotkeyMonitor = mon
        }

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let count = await self.queue.pendingCount
                let list  = await self.queue.pendingList
                let active = await self.sessions.activeCount
                let nots = await self.noticeStore.snapshot()
                await self.aggregator.ageActivities()
                await self.aggregator.pruneStale(staleAfter: 600)
                let cards = await self.aggregator.snapshot()
                // Auto-approve any pending request whose tool matches prefs,
                // or when Claude Code itself is in auto-accept mode.
                let snap = await MainActor.run { self.prefs }
                let ccAutoMode = Self.claudeAutoMode()
                for req in list {
                    // Never auto-approve a Bash command that matches the
                    // dangerous-pattern heuristic — always force human review.
                    if DangerousCommand.isDangerous(payload: req.payload) { continue }
                    let allow = snap.shouldAutoApprove(toolName: Self.toolName(req))
                              || ccAutoMode
                              || Self.payloadSignalsAutoMode(req.payload)
                    if allow {
                        await self.queue.resolve(
                            id: req.id,
                            with: ApprovalResponse(decision: .approve, reason: "auto-approved")
                        )
                    }
                }
                await MainActor.run {
                    self.pendingCount = count
                    self.pending = list
                    self.activeSessionsCount = active
                    self.notices = nots
                    self.sessionCards = cards
                    if count != self.lastPendingCount {
                        self.lastPendingCount = count
                        self.panelController?.refresh()
                    }
                    // Follow mouse-active screen: reposition when cursor
                    // crosses screens. Skip when user has lockToScreen on.
                    if !self.prefs.lockToScreen {
                        let mouse = NSEvent.mouseLocation
                        if let hit = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
                            let sid = ObjectIdentifier(hit)
                            if sid != self.lastScreenID {
                                self.lastScreenID = sid
                                self.panelController?.refresh()
                            }
                        }
                    }
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    @MainActor
    private func handleEventArrived(_ event: EventName) {
        switch event {
        case .permissionRequest, .preToolUse:
            soundPlayer.play(.permission, enabled: prefs.soundsEnabled)
        case .notification:
            lastNotificationAt = Date()
            soundPlayer.play(.notification, enabled: prefs.soundsEnabled)
        case .stop:
            // Suppress idle ding if a Notification just fired — they bracket
            // the same "agent waiting" moment and double-ding is noisy.
            if let t = lastNotificationAt, Date().timeIntervalSince(t) < 30 { return }
            soundPlayer.play(.idle, enabled: prefs.soundsEnabled)
        default:
            break
        }
    }

    static func toolName(_ r: PermissionRequest) -> String {
        if case .string(let s) = r.payload["tool_name"] ?? .null { return s }
        return ""
    }

    /// True when Claude Code's own settings.json signals "skip permission
    /// prompts" — usually via `skipAutoPermissionPrompt: true` (the flag
    /// you get from `claude --dangerously-skip-permissions`). Respect it
    /// so the user's existing CC auto-mode keeps working.
    private static var ccSettingsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
    }
    private static var ccAutoModeCache: (mtime: Date, value: Bool) = (.distantPast, false)
    static func claudeAutoMode() -> Bool {
        let attrs = try? FileManager.default.attributesOfItem(atPath: ccSettingsURL.path)
        let mtime = (attrs?[.modificationDate] as? Date) ?? .distantPast
        if mtime == ccAutoModeCache.mtime { return ccAutoModeCache.value }
        guard
            let data = try? Data(contentsOf: ccSettingsURL),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            ccAutoModeCache = (mtime, false); return false
        }
        let skip = (obj["skipAutoPermissionPrompt"] as? Bool) ?? false
        let mode = (obj["permission_mode"] as? String) ?? ""
        let value = skip
            || mode == "auto"
            || mode == "auto_accept"
            || mode == "yolo"
            || mode == "dangerously_skip"
        ccAutoModeCache = (mtime, value)
        return value
    }

    /// Some Claude Code builds embed the auto-mode flag in the hook payload
    /// itself, so check those fields as a per-request signal.
    static func payloadSignalsAutoMode(_ payload: [String: JSONValue]) -> Bool {
        for key in ["permission_mode", "permissionMode", "autoAccept", "skipPermissions"] {
            switch payload[key] ?? .null {
            case .bool(let b) where b: return true
            case .string(let s):
                let v = s.lowercased()
                if v == "auto" || v == "auto_accept" || v == "yolo"
                    || v == "dangerously_skip" || v == "skip" { return true }
            default: break
            }
        }
        return false
    }

    func approve(_ request: PermissionRequest) {
        Task { await queue.resolve(id: request.id, with: ApprovalResponse(decision: .approve)) }
    }

    func dismissNotice(_ notice: Notice) {
        Task { await noticeStore.dismiss(id: notice.id) }
    }

    func jumpNotice(_ notice: Notice) {
        Task { try? await jumper.jump(to: notice.locator) }
    }

    /// Add a tool to the auto-approve allow-list and persist preferences.
    func alwaysAllow(tool: String) {
        guard !tool.isEmpty else { return }
        var set = Set(prefs.autoApproveTools)
        set.insert(tool)
        prefs.autoApproveTools = Array(set).sorted()
    }

    func deny(_ request: PermissionRequest, reason: String? = nil) {
        Task { await queue.resolve(id: request.id, with: ApprovalResponse(decision: .deny, reason: reason)) }
    }

    func clearAllSessions() {
        Task { await aggregator.clearAll() }
    }

    func resetPrefs() {
        prefs = AppPreferences()
        panelController?.updateForMode(prefs.displayMode)
    }

    func revealLogsInFinder() {
        let url = paths.historyJSONL
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
        } else {
            NSWorkspace.shared.open(url.deletingLastPathComponent())
        }
    }

    func openHistoryViewer() {
        if historyWindow == nil {
            historyWindow = HistoryWindow(paths: paths)
        }
        historyWindow?.show()
    }

    func jumpToCard(_ card: SessionCard) {
        let loc = card.lastLocator
        Task {
            do { try await jumper.jump(to: loc) }
            catch { NSLog("agentisland: jump failed: \(error)") }
        }
    }

    func pickAskOption(card: SessionCard, option: AskOption) {
        if let n = card.pendingNotice { Task { await noticeStore.dismiss(id: n.id) } }
        let sid = card.id
        let loc = card.lastLocator
        let number = option.number
        Task {
            await aggregator.clearPendingNotice(sessionId: sid)
            try? await jumper.jump(to: loc)
            // Fallback: if jumper didn't change frontmost (tty=nil → no matcher
            // claimed it), force-activate the most likely terminal app so the
            // synthesized keystroke lands somewhere useful.
            await MainActor.run { Self.ensureTerminalFrontmost() }
            try? await Task.sleep(for: .milliseconds(350))
            await MainActor.run {
                KeystrokeInjector.typeDigitsAndReturn(number, tty: loc.tty)
            }
        }
    }

    /// Bring whichever terminal-class app is running to the front. Picks the
    /// most recently active one. No-op if none running.
    private static func ensureTerminalFrontmost() {
        let candidates: Set<String> = [
            "com.apple.Terminal",
            "com.googlecode.iterm2",
            "co.zeit.hyper",
            "io.alacritty",
            "com.mitchellh.ghostty",
            "dev.warp.Warp-Stable",
            "net.kovidgoyal.kitty"
        ]
        let running = NSWorkspace.shared.runningApplications
            .filter { candidates.contains($0.bundleIdentifier ?? "") }
            .sorted { ($0.launchDate ?? .distantPast) > ($1.launchDate ?? .distantPast) }
        guard let app = running.first else { return }
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == app.bundleIdentifier { return }
        app.activate(options: [])
    }

    func jump(_ request: PermissionRequest) {
        let loc = request.locator
        Task {
            do { try await jumper.jump(to: loc) }
            catch { NSLog("agentisland: jump failed: \(error)") }
        }
    }

    func shutdown() {
        // Mark clean exit + stop everything.
        refreshTask?.cancel()
        hotkeyMonitor?.stop()
        installer.stop()
        server.stop()
        let lastrun: [String: Any] = [
            "startedAt": ISO8601DateFormatter().string(from: Date()),
            "cleanExit": true,
            "pid": Int(getpid())
        ]
        if let data = try? JSONSerialization.data(withJSONObject: lastrun, options: [.sortedKeys]) {
            try? data.write(to: paths.lastRun)
        }
    }
}
