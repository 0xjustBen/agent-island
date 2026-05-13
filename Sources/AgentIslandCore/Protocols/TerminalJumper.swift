import Foundation

public protocol TerminalJumper: Sendable {
    var id: String { get }
    /// Identifies which `ProbedTerminal` this jumper handles. Default `.unknown`
    /// for composite or generic jumpers.
    var probedKind: ProbedTerminal { get }
    func canJump(to: TerminalLocator) async -> Bool
    func jump(to: TerminalLocator) async throws
}

public extension TerminalJumper {
    var probedKind: ProbedTerminal { .unknown }
}

public enum TerminalJumpError: Error, Equatable {
    case appNotRunning(String)
    case automationPermissionDenied
    case noMatchingSession
}
