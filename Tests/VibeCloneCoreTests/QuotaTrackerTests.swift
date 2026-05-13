import Testing
import Foundation
@testable import VibeCloneCore

private func mkRequest(_ sid: String, payload: [String: JSONValue] = [:],
                       source: String = "claude") -> PermissionRequest {
    var p = payload
    p["session_id"] = .string(sid)
    return PermissionRequest(
        id: UUID().uuidString, source: source, payload: p,
        locator: TerminalLocator(tty: nil, cwd: nil, ppid: nil),
        receivedAt: Date()
    )
}

@Test func ingest_extracts_top_level_usage() async {
    let t = QuotaTracker()
    let req = mkRequest("s1", payload: [
        "tool_name": .string("Bash"),
        "usage": .object([
            "input_tokens": .number(100),
            "output_tokens": .number(50)
        ])
    ])
    await t.ingest(event: .postToolUse, request: req)
    let snap = await t.snapshot()
    #expect(snap.perSession["s1"]?.inputTokens == 100)
    #expect(snap.perSession["s1"]?.outputTokens == 50)
    #expect(snap.dailyTotal.inputTokens == 100)
}

@Test func ingest_extracts_nested_tool_response_usage() async {
    let t = QuotaTracker()
    let req = mkRequest("s1", payload: [
        "tool_response": .object([
            "usage": .object([
                "input_tokens": .number(200),
                "output_tokens": .number(100),
                "cache_read_input_tokens": .number(50)
            ])
        ])
    ])
    await t.ingest(event: .postToolUse, request: req)
    let snap = await t.snapshot()
    #expect(snap.perSession["s1"]?.cacheReadTokens == 50)
}

@Test func ingest_ignores_non_postToolUse_events() async {
    let t = QuotaTracker()
    let req = mkRequest("s1", payload: [
        "usage": .object(["input_tokens": .number(100)])
    ])
    await t.ingest(event: .preToolUse, request: req)
    let snap = await t.snapshot()
    #expect(snap.perSession.isEmpty)
}

@Test func ingest_accumulates_across_calls() async {
    let t = QuotaTracker()
    for _ in 0..<3 {
        await t.ingest(event: .postToolUse, request: mkRequest("s1", payload: [
            "usage": .object(["input_tokens": .number(10), "output_tokens": .number(5)])
        ]))
    }
    let snap = await t.snapshot()
    #expect(snap.perSession["s1"]?.inputTokens == 30)
    #expect(snap.dailyTotal.outputTokens == 15)
}

@Test func ingest_partitions_perSource() async {
    let t = QuotaTracker()
    await t.ingest(event: .postToolUse, request: mkRequest("s1", payload: [
        "usage": .object(["input_tokens": .number(100)])
    ], source: "claude"))
    await t.ingest(event: .postToolUse, request: mkRequest("s2", payload: [
        "usage": .object(["input_tokens": .number(200)])
    ], source: "claude"))
    let snap = await t.snapshot()
    #expect(snap.perSource["claude"]?.inputTokens == 300)
}

@Test func ingestExternal_for_codex() async {
    let t = QuotaTracker()
    await t.ingestExternal(
        sessionId: "cx1", source: "codex", model: "gpt-5",
        usage: TokenUsage(inputTokens: 1_000_000, outputTokens: 500_000)
    )
    let snap = await t.snapshot()
    let total = snap.perSession["cx1"]!
    #expect(total.inputTokens == 1_000_000)
    // 1M input @ $5 + 0.5M output @ $15 = $5 + $7.5 = $12.5
    #expect(abs(total.totalCostUSD - 12.5) < 0.001)
}

@Test func cost_assigned_from_pricing_table() async {
    let t = QuotaTracker()
    await t.ingest(event: .postToolUse, request: mkRequest("s1", payload: [
        "model": .string("claude-sonnet-4"),
        "usage": .object([
            "input_tokens": .number(1_000_000),
            "output_tokens": .number(1_000_000)
        ])
    ]))
    let snap = await t.snapshot()
    #expect(abs(snap.dailyTotal.totalCostUSD - 18.0) < 0.001)
}

@Test func resetDaily_clears_source_and_total_but_keeps_session() async {
    let t = QuotaTracker()
    await t.ingest(event: .postToolUse, request: mkRequest("s1", payload: [
        "usage": .object(["input_tokens": .number(100)])
    ]))
    await t.resetDaily()
    let snap = await t.snapshot()
    #expect(snap.dailyTotal == .zero)
    #expect(snap.perSource.isEmpty)
    #expect(snap.perSession["s1"]?.inputTokens == 100)   // session retained
}
