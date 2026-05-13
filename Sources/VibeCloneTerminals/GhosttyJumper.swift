import Foundation
import AppKit
import VibeCloneCore

public struct GhosttyJumper: TerminalJumper {
    public let id = "ghostty"
    public let probedKind: ProbedTerminal = .ghostty
    public init() {}

    public func canJump(to: TerminalLocator) async -> Bool {
        AppKitActivate.isRunning(bundleId: "com.mitchellh.ghostty")
    }

    public func jump(to locator: TerminalLocator) async throws {
        guard await canJump(to: locator) else { throw TerminalJumpError.appNotRunning("Ghostty") }
        // Ghostty's AppleScript dictionary is minimal; just activate.
        try? AppKitActivate.runAppleScript(#"""
        tell application "Ghostty"
            activate
        end tell
        """#)
        try await AppKitActivate.activate(bundleId: "com.mitchellh.ghostty")
    }
}
