import Foundation
import AppKit
import VibeCloneCore

/// Tries underlying jumpers in order. The first `canJump == true` wins.
public struct CompositeJumper: TerminalJumper {
    public let id = "composite"
    public let jumpers: [any TerminalJumper]

    public init(jumpers: [any TerminalJumper]) { self.jumpers = jumpers }

    /// Default Phase 1 composite: iTerm2 first (richer), Terminal.app fallback.
    public static func `default`() -> CompositeJumper {
        CompositeJumper(jumpers: [ITerm2Jumper(), TerminalAppJumper()])
    }

    public func canJump(to loc: TerminalLocator) async -> Bool {
        for j in jumpers {
            if await j.canJump(to: loc) { return true }
        }
        return false
    }

    public func jump(to loc: TerminalLocator) async throws {
        // Prefer the jumper whose app is running. If multiple are running,
        // prefer one whose tty matches the locator (heuristic: tty path components).
        var lastError: Error = TerminalJumpError.noMatchingSession
        for j in jumpers where await j.canJump(to: loc) {
            do { try await j.jump(to: loc); return }
            catch { lastError = error }
        }
        throw lastError
    }
}
