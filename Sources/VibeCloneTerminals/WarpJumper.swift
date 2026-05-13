import Foundation
import AppKit
import VibeCloneCore

public struct WarpJumper: TerminalJumper {
    public let id = "warp"
    public let probedKind: ProbedTerminal = .warp
    public init() {}

    public func canJump(to: TerminalLocator) async -> Bool {
        AppKitActivate.isRunning(bundleId: "dev.warp.Warp-Stable")
    }

    public func jump(to locator: TerminalLocator) async throws {
        guard await canJump(to: locator) else { throw TerminalJumpError.appNotRunning("Warp") }
        try? AppKitActivate.runAppleScript(#"""
        tell application "Warp"
            activate
        end tell
        """#)
        try await AppKitActivate.activate(bundleId: "dev.warp.Warp-Stable")
    }
}
