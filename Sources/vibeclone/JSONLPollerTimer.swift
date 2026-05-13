import Foundation
import VibeCloneCore

@MainActor
final class JSONLPollerTimer {
    private var timer: Timer?
    private var cursor = SessionLogPoller.Cursor()
    private let quota: QuotaTracker
    private let home: URL

    init(quota: QuotaTracker,
         home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.quota = quota
        self.home = home
    }

    func start(interval: TimeInterval = 60) {
        timer?.invalidate()
        // Run once immediately, then on the timer.
        Task { await self.tick() }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.tick() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() async {
        let mounts: [(URL, String)] = [
            (home.appendingPathComponent(".codex/sessions"), "codex"),
            (home.appendingPathComponent(".kimi/sessions"),  "kimi"),
        ]
        for (dir, source) in mounts {
            let (readings, newCursor) = SessionLogPoller.scan(dir: dir, source: source, cursor: cursor)
            cursor = newCursor
            for r in readings {
                await quota.ingestExternal(sessionId: r.sessionId, source: r.source,
                                           model: r.model, usage: r.usage)
            }
        }
    }
}
