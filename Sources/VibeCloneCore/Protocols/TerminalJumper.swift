import Foundation

public protocol TerminalJumper: Sendable {
    var id: String { get }
    func canJump(to: TerminalLocator) async -> Bool
    func jump(to: TerminalLocator) async throws
}

public enum TerminalJumpError: Error, Equatable {
    case appNotRunning(String)
    case automationPermissionDenied
    case noMatchingSession
}
