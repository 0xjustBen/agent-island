import Foundation

public actor QuotaTracker {
    private var perSession: [String: TokenUsage] = [:]
    private var perSource: [String: TokenUsage] = [:]
    private var dailyTotal: TokenUsage = .zero
    private var lastResetDay: Date = Date()

    public init() {}

    /// Feed an event. Only `.postToolUse` carries usage data for Claude.
    /// Codex/Kimi come through the JSONL poller via `ingestExternal`.
    public func ingest(event: EventName, request: PermissionRequest) {
        guard event == .postToolUse else { return }
        guard let usage = extractUsage(from: request.payload) else { return }

        let model = extractModel(from: request.payload) ?? defaultModel(for: request.source)
        var u = usage
        u.totalCostUSD = UsagePricing.costUSD(model: model, usage: usage)

        let sid = sessionId(from: request)
        perSession[sid, default: .zero] += u
        perSource[request.source, default: .zero] += u
        dailyTotal += u
    }

    /// Direct injection from JSONL poller for Codex/Kimi/etc.
    public func ingestExternal(sessionId: String, source: String, model: String,
                               usage: TokenUsage) {
        var u = usage
        u.totalCostUSD = UsagePricing.costUSD(model: model, usage: usage)
        perSession[sessionId, default: .zero] += u
        perSource[source, default: .zero] += u
        dailyTotal += u
    }

    /// Snapshot current totals.
    public func snapshot() -> QuotaSnapshot {
        QuotaSnapshot(perSession: perSession, perSource: perSource, dailyTotal: dailyTotal)
    }

    /// Reset daily aggregates. Per-session retained (small leak; will clear
    /// on app restart).
    public func resetDaily(now: Date = Date()) {
        perSource = [:]
        dailyTotal = .zero
        lastResetDay = now
    }

    /// Convenience: call before snapshot to roll over at local midnight.
    public func rolloverIfNewDay(now: Date = Date()) {
        let cal = Calendar.current
        if !cal.isDate(now, inSameDayAs: lastResetDay) {
            resetDaily(now: now)
        }
    }

    // MARK: - Helpers

    private func sessionId(from request: PermissionRequest) -> String {
        if case .string(let s) = request.payload["session_id"] ?? .null { return s }
        return request.id
    }

    /// CC's PostToolUse payload format varies by version.
    /// We look in two places: top-level "usage", or "tool_response.usage".
    private func extractUsage(from payload: [String: JSONValue]) -> TokenUsage? {
        // Top-level usage
        if case .object(let u) = payload["usage"] ?? .null {
            return parseUsage(u)
        }
        // Nested tool_response
        if case .object(let tr) = payload["tool_response"] ?? .null,
           case .object(let u) = tr["usage"] ?? .null {
            return parseUsage(u)
        }
        return nil
    }

    private func parseUsage(_ obj: [String: JSONValue]) -> TokenUsage? {
        let i = intValue(obj["input_tokens"])
        let o = intValue(obj["output_tokens"])
        let cr = intValue(obj["cache_read_input_tokens"]) ?? intValue(obj["cache_read_tokens"])
        let cc = intValue(obj["cache_creation_input_tokens"]) ?? intValue(obj["cache_create_tokens"])
        guard (i ?? 0) + (o ?? 0) + (cr ?? 0) + (cc ?? 0) > 0 else { return nil }
        return TokenUsage(
            inputTokens: i ?? 0,
            outputTokens: o ?? 0,
            cacheReadTokens: cr ?? 0,
            cacheCreateTokens: cc ?? 0,
            totalCostUSD: 0
        )
    }

    private func intValue(_ v: JSONValue?) -> Int? {
        if case .number(let n) = v ?? .null { return Int(n) }
        return nil
    }

    private func extractModel(from payload: [String: JSONValue]) -> String? {
        if case .string(let s) = payload["model"] ?? .null { return s }
        return nil
    }

    private func defaultModel(for source: String) -> String {
        switch source.lowercased() {
        case "claude":   return "claude-sonnet-4"
        case "codex":    return "codex"
        case "kimi":     return "kimi-k2"
        case "gemini":   return "gemini-2.5-pro"
        default:         return "default"
        }
    }
}
