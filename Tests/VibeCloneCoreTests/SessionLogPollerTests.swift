import Testing
import Foundation
@testable import VibeCloneCore

@Test func parseLine_codex_shape() {
    let obj: [String: Any] = [
        "model": "gpt-5",
        "usage": ["input_tokens": 100, "output_tokens": 50]
    ]
    let result = SessionLogPoller.parseLine(obj)!
    #expect(result.model == "gpt-5")
    #expect(result.usage.inputTokens == 100)
    #expect(result.usage.outputTokens == 50)
}

@Test func parseLine_openai_legacy_field_names() {
    let obj: [String: Any] = [
        "model": "codex",
        "usage": ["prompt_tokens": 200, "completion_tokens": 75]
    ]
    let r = SessionLogPoller.parseLine(obj)!
    #expect(r.usage.inputTokens == 200)
    #expect(r.usage.outputTokens == 75)
}

@Test func parseLine_returns_nil_when_no_usage() {
    let obj: [String: Any] = ["model": "x", "content": "hello"]
    #expect(SessionLogPoller.parseLine(obj) == nil)
}

@Test func parseLine_returns_nil_when_all_zero() {
    let obj: [String: Any] = [
        "model": "x", "usage": ["input_tokens": 0, "output_tokens": 0]
    ]
    #expect(SessionLogPoller.parseLine(obj) == nil)
}

@Test func scan_processes_new_jsonl_lines() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("codex-test-\(UUID())")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let file = dir.appendingPathComponent("sess-abc.jsonl")
    let line1 = #"{"model":"gpt-5","usage":{"input_tokens":10,"output_tokens":5}}"#
    let line2 = #"{"model":"gpt-5","usage":{"input_tokens":20,"output_tokens":15}}"#
    try (line1 + "\n" + line2 + "\n").write(to: file, atomically: true, encoding: .utf8)

    let (readings, c1) = SessionLogPoller.scan(dir: dir, source: "codex", cursor: .init())
    #expect(readings.count == 2)
    #expect(readings[0].sessionId == "sess-abc")
    #expect(readings[1].usage.outputTokens == 15)
    #expect(c1.byteOffsets.count == 1)
    let cursorKey = c1.byteOffsets.keys.first!
    let savedOffset = c1.byteOffsets[cursorKey]!
    #expect(savedOffset > 0)

    // Append a third line — only that one should come back on next scan.
    let line3 = #"{"model":"gpt-5","usage":{"input_tokens":7,"output_tokens":3}}"#
    let h = try FileHandle(forWritingTo: file)
    try h.seekToEnd()
    try h.write(contentsOf: (line3 + "\n").data(using: .utf8)!)
    try h.close()

    let (readings2, c2) = SessionLogPoller.scan(dir: dir, source: "codex", cursor: c1)
    #expect(readings2.count == 1)
    #expect(readings2[0].usage.inputTokens == 7)
    #expect(c2.byteOffsets[cursorKey]! > savedOffset)

    try? FileManager.default.removeItem(at: dir)
}

@Test func scan_ignores_non_jsonl_files() throws {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("codex-test-\(UUID())")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try "not jsonl".write(to: dir.appendingPathComponent("note.txt"),
                          atomically: true, encoding: .utf8)
    let (readings, _) = SessionLogPoller.scan(dir: dir, source: "codex", cursor: .init())
    #expect(readings.isEmpty)
    try? FileManager.default.removeItem(at: dir)
}

@Test func scan_handles_missing_directory_gracefully() {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("does-not-exist-\(UUID())")
    let (readings, c) = SessionLogPoller.scan(dir: dir, source: "codex", cursor: .init())
    #expect(readings.isEmpty)
    #expect(c.byteOffsets.isEmpty)
}
