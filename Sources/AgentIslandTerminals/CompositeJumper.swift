import Foundation
import AppKit
import AgentIslandCore

/// Tries underlying jumpers — prober result first (if available), then iteration.
public struct CompositeJumper: TerminalJumper {
    public let id = "composite"
    public let probedKind: ProbedTerminal = .unknown
    public let jumpers: [any TerminalJumper]
    public let prober: (@Sendable (pid_t) -> ProbedTerminal)?

    public init(jumpers: [any TerminalJumper],
                prober: (@Sendable (pid_t) -> ProbedTerminal)? = nil) {
        self.jumpers = jumpers
        self.prober = prober
    }

    /// Phase 3 default composite: all 9 jumpers + TerminalProber.
    public static func `default`() -> CompositeJumper {
        let iterm = ITerm2Jumper()
        let term  = TerminalAppJumper()
        let ghost = GhosttyJumper()
        let warp  = WarpJumper()
        let code  = VSCodeJumper()
        let cur   = CursorJumper()
        let alac  = AlacrittyJumper()
        let kitty = KittyJumper()
        // Host jumpers for tmux: everything except tmux itself.
        let hosts: [any TerminalJumper] = [iterm, term, ghost, warp, code, cur, alac, kitty]
        let tmux  = TmuxJumper(hostJumpers: hosts)

        return CompositeJumper(
            jumpers: [tmux, iterm, term, ghost, warp, code, cur, alac, kitty],
            prober: { ppid in TerminalProber.probeLive(startPid: ppid) }
        )
    }

    public func canJump(to loc: TerminalLocator) async -> Bool {
        for j in jumpers {
            if await j.canJump(to: loc) { return true }
        }
        return false
    }

    public func jump(to loc: TerminalLocator) async throws {
        var lastError: Error = TerminalJumpError.noMatchingSession
        var triedId: String? = nil

        // 1. Prober pre-selection
        if let prober, let ppid = loc.ppid {
            let probed = prober(ppid)
            if probed != .unknown,
               let preferred = jumpers.first(where: { $0.probedKind == probed }),
               await preferred.canJump(to: loc) {
                triedId = preferred.id
                do { try await preferred.jump(to: loc); return }
                catch { lastError = error /* fall through to iteration */ }
            }
        }
        // 2. Fall-back iteration (skip the jumper we already tried)
        for j in jumpers {
            if j.id == triedId { continue }
            guard await j.canJump(to: loc) else { continue }
            do { try await j.jump(to: loc); return }
            catch { lastError = error }
        }
        throw lastError
    }
}
