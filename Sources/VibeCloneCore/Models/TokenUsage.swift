import Foundation

public struct TokenUsage: Hashable, Sendable, Codable {
    public var inputTokens: Int
    public var outputTokens: Int
    public var cacheReadTokens: Int
    public var cacheCreateTokens: Int
    public var totalCostUSD: Double

    public init(inputTokens: Int = 0,
                outputTokens: Int = 0,
                cacheReadTokens: Int = 0,
                cacheCreateTokens: Int = 0,
                totalCostUSD: Double = 0) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheCreateTokens = cacheCreateTokens
        self.totalCostUSD = totalCostUSD
    }

    public static let zero = TokenUsage()

    /// Sum of all token fields.
    public var totalTokens: Int {
        inputTokens + outputTokens + cacheReadTokens + cacheCreateTokens
    }

    public static func + (lhs: TokenUsage, rhs: TokenUsage) -> TokenUsage {
        TokenUsage(
            inputTokens:       lhs.inputTokens       + rhs.inputTokens,
            outputTokens:      lhs.outputTokens      + rhs.outputTokens,
            cacheReadTokens:   lhs.cacheReadTokens   + rhs.cacheReadTokens,
            cacheCreateTokens: lhs.cacheCreateTokens + rhs.cacheCreateTokens,
            totalCostUSD:      lhs.totalCostUSD      + rhs.totalCostUSD
        )
    }

    public static func += (lhs: inout TokenUsage, rhs: TokenUsage) {
        lhs = lhs + rhs
    }
}
