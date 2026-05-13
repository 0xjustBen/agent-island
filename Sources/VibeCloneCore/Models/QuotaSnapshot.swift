import Foundation

public struct QuotaSnapshot: Sendable, Hashable, Codable {
    public let perSession: [String: TokenUsage]   // session_id → usage
    public let perSource: [String: TokenUsage]    // claude / codex / kimi → daily total
    public let dailyTotal: TokenUsage

    public init(perSession: [String: TokenUsage] = [:],
                perSource: [String: TokenUsage] = [:],
                dailyTotal: TokenUsage = .zero) {
        self.perSession = perSession
        self.perSource = perSource
        self.dailyTotal = dailyTotal
    }

    public static let empty = QuotaSnapshot()
}
