import Foundation
import AgentIslandCore
import AgentIslandAdapters
import AgentIslandLauncher

@MainActor
final class HookInstaller {
    private let adapters: [AgentAdapter]
    private let paths: Paths
    private var timer: Timer?
    private(set) var lastError: Error?

    init(adapters: [AgentAdapter], paths: Paths) {
        self.adapters = adapters
        self.paths = paths
    }

    /// One-shot install at launch: write launcher script + ensure all adapter hooks present.
    func installNow() {
        do {
            try LauncherWriter.write(paths: paths)
        } catch { lastError = error }
        for a in adapters {
            do { try a.installHooks(paths: paths) }
            catch { lastError = error }
        }
    }

    /// Background loop: every `interval` seconds, re-heal hooks if user/3rd party stripped them.
    func startHealing(interval: TimeInterval = 30, enabled: @escaping @MainActor () -> Bool) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard enabled() else { return }
                // Re-write launcher each cycle (cheap, atomic) to recover from user rm.
                _ = try? LauncherWriter.write(paths: self.paths)
                for a in self.adapters {
                    _ = try? a.healHooks(paths: self.paths)
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
