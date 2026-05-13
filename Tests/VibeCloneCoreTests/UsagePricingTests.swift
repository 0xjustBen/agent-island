import Testing
import Foundation
@testable import VibeCloneCore

@Test func tokenUsage_sums() {
    var a = TokenUsage(inputTokens: 100, outputTokens: 50)
    let b = TokenUsage(inputTokens: 200, outputTokens: 25, cacheReadTokens: 10)
    a += b
    #expect(a.inputTokens == 300)
    #expect(a.outputTokens == 75)
    #expect(a.cacheReadTokens == 10)
}

@Test func tokenUsage_totalTokens() {
    let u = TokenUsage(inputTokens: 1, outputTokens: 2, cacheReadTokens: 3, cacheCreateTokens: 4)
    #expect(u.totalTokens == 10)
}

@Test func pricing_known_model() {
    let p = UsagePricing.price(for: "claude-sonnet-4")
    #expect(p.inputPerM == 3.00)
    #expect(p.outputPerM == 15.00)
}

@Test func pricing_prefix_match() {
    // "claude-sonnet-4-20250529" should still find claude-sonnet-4 price.
    let p = UsagePricing.price(for: "claude-sonnet-4-20250529")
    #expect(p.outputPerM == 15.00)
}

@Test func pricing_unknown_model_falls_back_to_default() {
    let p = UsagePricing.price(for: "unknown-llm-xyz")
    #expect(p.inputPerM == 1.00)
}

@Test func costUSD_simple() {
    let usage = TokenUsage(inputTokens: 1_000_000, outputTokens: 1_000_000)
    let cost = UsagePricing.costUSD(model: "claude-sonnet-4", usage: usage)
    // 1M input @ $3 + 1M output @ $15 = $18
    #expect(cost == 18.0)
}

@Test func costUSD_with_cache() {
    let usage = TokenUsage(inputTokens: 0, outputTokens: 0,
                           cacheReadTokens: 1_000_000, cacheCreateTokens: 0)
    let cost = UsagePricing.costUSD(model: "claude-sonnet-4", usage: usage)
    #expect(cost == 0.30)
}

@Test func quotaSnapshot_empty_is_zero() {
    let s = QuotaSnapshot.empty
    #expect(s.dailyTotal == .zero)
    #expect(s.perSession.isEmpty)
    #expect(s.perSource.isEmpty)
}
