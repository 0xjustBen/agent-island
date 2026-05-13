import Testing
import Foundation
@testable import AgentIslandCore

@Test func appends_jsonl_record_with_event_name() async throws {
    let tmp = FileManager.default.temporaryDirectory
        .appendingPathComponent("hist-\(UUID()).jsonl")
    let w = HistoryWriter(url: tmp, rotateAtBytes: 1_000_000)
    let r = PermissionRequest(id: "r1", source: "claude", payload: ["tool_name": .string("Bash")],
        locator: TerminalLocator(tty: nil, cwd: "/x", ppid: 1),
        receivedAt: Date(timeIntervalSince1970: 100))
    await w.record(event: .permissionRequest, request: r,
                   decision: ApprovalResponse(decision: .approve), latencyMs: 42)
    await w.flush()
    let content = try String(contentsOf: tmp)
    let lines = content.split(separator: "\n")
    #expect(lines.count == 1)
    #expect(content.contains("\"event\":\"PermissionRequest\""))
    #expect(content.contains("\"decision\":\"approve\""))
    #expect(content.contains("\"latency_ms\":42"))
    try FileManager.default.removeItem(at: tmp)
}

@Test func rotates_when_size_exceeded() async throws {
    let tmp = FileManager.default.temporaryDirectory
        .appendingPathComponent("hist-\(UUID()).jsonl")
    let w = HistoryWriter(url: tmp, rotateAtBytes: 100)
    let bigPayload: [String: JSONValue] = [
        "command": .string(String(repeating: "x", count: 200))
    ]
    let r = PermissionRequest(id: "r1", source: "claude", payload: bigPayload,
        locator: TerminalLocator(tty: nil, cwd: nil, ppid: nil),
        receivedAt: Date())
    await w.record(event: .preToolUse, request: r,
                   decision: ApprovalResponse(decision: .approve), latencyMs: 1)
    await w.record(event: .postToolUse, request: r,
                   decision: ApprovalResponse(decision: .approve), latencyMs: 2)
    await w.flush()
    let rotated = tmp.appendingPathExtension("1")
    #expect(FileManager.default.fileExists(atPath: rotated.path))
    try? FileManager.default.removeItem(at: tmp)
    try? FileManager.default.removeItem(at: rotated)
}

@Test func conforms_to_HistoryRecording() async throws {
    let tmp = FileManager.default.temporaryDirectory
        .appendingPathComponent("hist-\(UUID()).jsonl")
    let w: any HistoryRecording = HistoryWriter(url: tmp)
    let r = PermissionRequest(id: "r1", source: "claude", payload: [:],
        locator: TerminalLocator(tty: nil, cwd: nil, ppid: nil),
        receivedAt: Date())
    await w.record(event: .stop, request: r,
                   decision: ApprovalResponse(decision: .approve), latencyMs: 0)
    try? FileManager.default.removeItem(at: tmp)
}
