import SwiftUI
import VibeCloneCore
import VibeCloneAdapters
import VibeCloneLauncher
import VibeCloneTerminals

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
    let quotaTracker: QuotaTracker
    private(set) var quotaSnapshot: QuotaSnapshot = .empty
    let router: EventRouter
    let server: SocketServer
    let installer: HookInstaller
    private let jumper = CompositeJumper.default()
    private var refreshTask: Task<Void, Never>?
    private(set) var panelController: PanelController!
    private(set) var soundPlayer: SoundPlayer!
    private(set) var hotkeyMonitor: HotkeyMonitor?
    private var lastPendingCount: Int = -1

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
        self.quotaTracker = QuotaTracker()
        let adapter = ClaudeCodeAdapter()
        self.router = EventRouter(queue: queue, sessions: sessions,
                                  history: history, adapter: adapter,
                                  notices: noticeStore,
                                  aggregator: aggregator,
                                  quota: quotaTracker)
        self.server = SocketServer(router: router, paths: p)
        self.installer = HookInstaller(adapters: [adapter], paths: p)
        boot()
    }

    private func boot() {
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
            NSLog("vibeclone: server start failed: \(error)")
        }

        panelController.updateForMode(prefs.displayMode)

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
                let cards = await self.aggregator.snapshot()
                await self.quotaTracker.rolloverIfNewDay()
                let qs = await self.quotaTracker.snapshot()
                // Auto-approve any pending request whose tool matches prefs.
                let snap = await MainActor.run { self.prefs }
                for req in list {
                    if snap.shouldAutoApprove(toolName: Self.toolName(req)) {
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
                    self.quotaSnapshot = qs
                    if count != self.lastPendingCount {
                        self.lastPendingCount = count
                        self.panelController?.refresh()
                    }
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    @MainActor
    private func handleEventArrived(_ event: EventName) {
        switch event {
        case .permissionRequest:
            soundPlayer.play(.permission, enabled: prefs.soundsEnabled)
        case .notification:
            soundPlayer.play(.notification, enabled: prefs.soundsEnabled)
        case .stop:
            soundPlayer.play(.idle, enabled: prefs.soundsEnabled)
        default:
            break
        }
    }

    static func toolName(_ r: PermissionRequest) -> String {
        if case .string(let s) = r.payload["tool_name"] ?? .null { return s }
        return ""
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

    func deny(_ request: PermissionRequest, reason: String? = nil) {
        Task { await queue.resolve(id: request.id, with: ApprovalResponse(decision: .deny, reason: reason)) }
    }

    func jumpToCard(_ card: SessionCard) {
        let loc = card.lastLocator
        Task {
            do { try await jumper.jump(to: loc) }
            catch { NSLog("vibeclone: jump failed: \(error)") }
        }
    }

    func pickAskOption(card: SessionCard, option: AskOption) {
        // Phase 7: inject keystrokes. For now, dismiss notice and jump.
        if let n = card.pendingNotice { Task { await noticeStore.dismiss(id: n.id) } }
        jumpToCard(card)
    }

    func jump(_ request: PermissionRequest) {
        let loc = request.locator
        Task {
            do { try await jumper.jump(to: loc) }
            catch { NSLog("vibeclone: jump failed: \(error)") }
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
