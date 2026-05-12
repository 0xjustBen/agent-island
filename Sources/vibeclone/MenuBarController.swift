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
    var prefs: AppPreferences {
        didSet { prefs.save(paths: paths) }
    }

    private let paths: Paths
    let queue: ApprovalQueue
    let sessions: ActiveSessions
    let history: HistoryWriter
    let router: EventRouter
    let server: SocketServer
    let installer: HookInstaller
    private let jumper = CompositeJumper.default()
    private var refreshTask: Task<Void, Never>?
    private(set) var panelController: PanelController!
    private(set) var soundPlayer: SoundPlayer!
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
        let adapter = ClaudeCodeAdapter()
        self.router = EventRouter(queue: queue, sessions: sessions,
                                  history: history, adapter: adapter)
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

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let count = await self.queue.pendingCount
                let list  = await self.queue.pendingList
                let active = await self.sessions.activeCount
                await MainActor.run {
                    self.pendingCount = count
                    self.pending = list
                    self.activeSessionsCount = active
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

    func approve(_ request: PermissionRequest) {
        Task { await queue.resolve(id: request.id, with: ApprovalResponse(decision: .approve)) }
    }

    func deny(_ request: PermissionRequest, reason: String? = nil) {
        Task { await queue.resolve(id: request.id, with: ApprovalResponse(decision: .deny, reason: reason)) }
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
