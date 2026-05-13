import Foundation

/// Static per-million-token prices. Best-effort cost estimate. Updated as
/// part of releases, not user-configurable, to preserve zero-telemetry stance.
public enum UsagePricing {

    public struct Price: Sendable {
        public let inputPerM: Double
        public let outputPerM: Double
        public let cacheReadPerM: Double
        public let cacheCreatePerM: Double
    }

    /// Lowercase model names → price. Caller should lowercase before lookup.
    public static let table: [String: Price] = [
        // Claude (2026 prices, in USD per 1M tokens)
        "claude-sonnet-4":  Price(inputPerM: 3.00, outputPerM: 15.00, cacheReadPerM: 0.30, cacheCreatePerM: 3.75),
        "claude-opus-4":    Price(inputPerM: 15.00, outputPerM: 75.00, cacheReadPerM: 1.50, cacheCreatePerM: 18.75),
        "claude-haiku-4":   Price(inputPerM: 0.80, outputPerM: 4.00, cacheReadPerM: 0.08, cacheCreatePerM: 1.00),
        // OpenAI
        "gpt-5":            Price(inputPerM: 5.00, outputPerM: 15.00, cacheReadPerM: 0.50, cacheCreatePerM: 0.0),
        "gpt-5-mini":       Price(inputPerM: 0.30, outputPerM: 1.20, cacheReadPerM: 0.03, cacheCreatePerM: 0.0),
        "codex":            Price(inputPerM: 5.00, outputPerM: 15.00, cacheReadPerM: 0.50, cacheCreatePerM: 0.0),
        // Moonshot
        "kimi-k2":          Price(inputPerM: 0.60, outputPerM: 2.50, cacheReadPerM: 0.06, cacheCreatePerM: 0.0),
        // Google
        "gemini-2.5-pro":   Price(inputPerM: 1.25, outputPerM: 5.00, cacheReadPerM: 0.13, cacheCreatePerM: 0.0),
        // Fallback
        "default":          Price(inputPerM: 1.00, outputPerM: 5.00, cacheReadPerM: 0.10, cacheCreatePerM: 0.0),
    ]

    public static func price(for model: String) -> Price {
        let key = model.lowercased()
        if let p = table[key] { return p }
        // Match by family prefix.
        for (k, v) in table {
            if key.hasPrefix(k) { return v }
        }
        return table["default"]!
    }

    /// Cost in USD for the given usage at the given model's price.
    public static func costUSD(model: String, usage: TokenUsage) -> Double {
        let p = price(for: model)
        let perM = 1_000_000.0
        return Double(usage.inputTokens)       * p.inputPerM       / perM
             + Double(usage.outputTokens)      * p.outputPerM      / perM
             + Double(usage.cacheReadTokens)   * p.cacheReadPerM   / perM
             + Double(usage.cacheCreateTokens) * p.cacheCreatePerM / perM
    }
}
