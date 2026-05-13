import Foundation

/// Parses Codex/Kimi-style session JSONL files for token usage.
/// Each line is a JSON object representing a turn; we look for an `usage` field.
public enum SessionLogPoller {

    public struct Reading: Hashable, Sendable {
        public let sessionId: String
        public let source: String
        public let model: String
        public let usage: TokenUsage
        public init(sessionId: String, source: String, model: String, usage: TokenUsage) {
            self.sessionId = sessionId; self.source = source
            self.model = model; self.usage = usage
        }
    }

    /// Tracks how many bytes of each file we've already consumed so we never
    /// re-charge tokens across polls. Implemented as a value type — caller
    /// holds the dictionary, updates on each scan.
    public struct Cursor: Sendable {
        public var byteOffsets: [URL: UInt64]
        public init(byteOffsets: [URL: UInt64] = [:]) { self.byteOffsets = byteOffsets }
    }

    /// Scan a directory for `*.jsonl` files, read new bytes since last cursor
    /// position, parse usage per line, return readings + updated cursor.
    public static func scan(dir: URL,
                            source: String,
                            cursor: Cursor) -> (readings: [Reading], cursor: Cursor) {
        var c = cursor
        var readings: [Reading] = []
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: dir,
                includingPropertiesForKeys: [.fileSizeKey]) else {
            return ([], c)
        }
        for file in files where file.pathExtension == "jsonl" {
            let offset = c.byteOffsets[file] ?? 0
            guard let (lines, newOffset) = readSince(file: file, offset: offset) else { continue }
            c.byteOffsets[file] = newOffset
            let sessionId = file.deletingPathExtension().lastPathComponent
            for line in lines {
                guard let data = line.data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else { continue }
                guard let (model, usage) = parseLine(obj) else { continue }
                readings.append(Reading(sessionId: sessionId, source: source,
                                        model: model, usage: usage))
            }
        }
        return (readings, c)
    }

    /// Read bytes from `offset` to EOF. Returns split lines + new offset.
    public static func readSince(file: URL, offset: UInt64) -> (lines: [String], newOffset: UInt64)? {
        guard let h = try? FileHandle(forReadingFrom: file) else { return nil }
        defer { try? h.close() }
        try? h.seek(toOffset: offset)
        guard let data = try? h.readToEnd() else { return nil }
        let newOffset = offset + UInt64(data.count)
        guard let text = String(data: data, encoding: .utf8) else {
            return ([], newOffset)
        }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        return (lines, newOffset)
    }

    /// Extract `(model, usage)` from a turn JSON object.
    public static func parseLine(_ obj: [String: Any]) -> (model: String, usage: TokenUsage)? {
        let model = (obj["model"] as? String) ?? "default"

        // Codex/Kimi commonly emit `usage` with input_tokens/output_tokens.
        guard let usageObj = obj["usage"] as? [String: Any] else { return nil }
        let i  = (usageObj["input_tokens"]  as? Int) ?? (usageObj["prompt_tokens"]     as? Int) ?? 0
        let o  = (usageObj["output_tokens"] as? Int) ?? (usageObj["completion_tokens"] as? Int) ?? 0
        let cr = (usageObj["cache_read_input_tokens"]     as? Int) ?? (usageObj["cache_read_tokens"]   as? Int) ?? 0
        let cc = (usageObj["cache_creation_input_tokens"] as? Int) ?? (usageObj["cache_create_tokens"] as? Int) ?? 0
        guard i + o + cr + cc > 0 else { return nil }
        return (model, TokenUsage(inputTokens: i, outputTokens: o,
                                  cacheReadTokens: cr, cacheCreateTokens: cc,
                                  totalCostUSD: 0))
    }
}
