import Foundation

public enum ApprovalDecision: String, Codable, Sendable {
    case approve, deny, expired, error
}

public struct ApprovalResponse: Codable, Sendable {
    public let decision: ApprovalDecision
    public let reason: String?
    public init(decision: ApprovalDecision, reason: String? = nil) {
        self.decision = decision; self.reason = reason
    }
}
