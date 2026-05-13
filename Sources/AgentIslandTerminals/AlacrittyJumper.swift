import Foundation
import AppKit
import AgentIslandCore

public struct AlacrittyJumper: TerminalJumper {
    public let id = "alacritty"
    public let probedKind: ProbedTerminal = .alacritty
    public init() {}

    public func canJump(to: TerminalLocator) async -> Bool {
        AppKitActivate.isRunning(bundleId: "org.alacritty")
    }

    public func jump(to locator: TerminalLocator) async throws {
        guard await canJump(to: locator) else { throw TerminalJumpError.appNotRunning("Alacritty") }
        // Alacritty has no AppleScript / IPC. Best-effort: activate.
        try await AppKitActivate.activate(bundleId: "org.alacritty")
    }
}
