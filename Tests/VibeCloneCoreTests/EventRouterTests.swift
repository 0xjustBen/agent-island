import Testing
import Foundation
@testable import VibeCloneCore

private struct FakeAdapter: AgentAdapter {
    let id = "fake"
    let displayName = "Fake"
    let sourceFlag = "fake"
    let ipcKind: IPCKind = .stdinStdout

    func installHooks(paths: Paths) throws {}
    func healHooks(paths: Paths) throws -> Bool { false }
    func decodeStdin(_ raw: Data) throws -> (event: EventName, payload: [String: JSONValue]) {
        (.preToolUse, [:])
    }
    func encodeStdoutBody(event: EventName, decision: ApprovalDecision?, reason: String?) throws -> Data {
        if event == .permissionRequest {
            let str = "allow_or_deny=\(decision?.rawValue ?? "nil")"
            return Data(str.utf8)
        }
        return Data("{}".utf8)
    }
}

private actor FakeHistory: HistoryRecording {
    var records: [(EventName, String, ApprovalDecision)] = []
    func record(event: EventName, request: PermissionRequest,
                decision: ApprovalResponse, latencyMs: Int) {
        records.append((event, request.id, decision.decision))
    }
    func snapshot() -> [(EventName, String, ApprovalDecision)] { records }
}

private func mkReq(_ id: String, sid: String = "sess1", source: String = "claude") -> PermissionRequest {
    PermissionRequest(
        id: id, source: source,
        payload: ["session_id": .string(sid)],
        locator: TerminalLocator(tty: nil, cwd: nil, ppid: nil),
        receivedAt: Date()
    )
}

@Test func routes_permissionRequest_through_queue() async throws {
    let q = ApprovalQueue(timeout: .seconds(5))
    let s = ActiveSessions()
    let h = FakeHistory()
    let r = EventRouter(queue: q, sessions: s, history: h, adapter: FakeAdapter())

    Task { try? await Task.sleep(for: .milliseconds(30))
           await q.resolve(id: "r1", with: ApprovalResponse(decision: .approve)) }
    let res = await r.route(event: .permissionRequest, request: mkReq("r1"))
    #expect(String(data: res.stdoutJSON, encoding: .utf8) == "allow_or_deny=approve")
    let snap = await h.snapshot()
    #expect(snap.contains(where: { $0.0 == .permissionRequest && $0.2 == .approve }))
}

@Test func routes_sessionStart_to_ledger_and_returns_empty_object() async throws {
    let q = ApprovalQueue(); let s = ActiveSessions(); let h = FakeHistory()
    let r = EventRouter(queue: q, sessions: s, history: h, adapter: FakeAdapter())
    let res = await r.route(event: .sessionStart, request: mkReq("r2", sid: "abc"))
    #expect(res.stdoutJSON == Data("{}".utf8))
    let n = await s.activeCount
    #expect(n == 1)
    let all = await s.all
    #expect(all.first?.sessionId == "abc")
}

@Test func routes_subagentStart_and_stop_change_depth() async throws {
    let q = ApprovalQueue(); let s = ActiveSessions(); let h = FakeHistory()
    let r = EventRouter(queue: q, sessions: s, history: h, adapter: FakeAdapter())
    _ = await r.route(event: .sessionStart, request: mkReq("r1", sid: "x"))
    _ = await r.route(event: .subagentStart, request: mkReq("r2", sid: "x"))
    _ = await r.route(event: .subagentStart, request: mkReq("r3", sid: "x"))
    let d = await s.subagentDepth(sessionId: "x")
    #expect(d == 2)
    _ = await r.route(event: .subagentStop, request: mkReq("r4", sid: "x"))
    let d2 = await s.subagentDepth(sessionId: "x")
    #expect(d2 == 1)
}

@Test func routes_sessionEnd_removes_session() async throws {
    let q = ApprovalQueue(); let s = ActiveSessions(); let h = FakeHistory()
    let r = EventRouter(queue: q, sessions: s, history: h, adapter: FakeAdapter())
    _ = await r.route(event: .sessionStart, request: mkReq("r1", sid: "z"))
    _ = await r.route(event: .sessionEnd, request: mkReq("r2", sid: "z"))
    let n = await s.activeCount
    #expect(n == 0)
}

@Test func record_only_events_produce_empty_body() async throws {
    let q = ApprovalQueue(); let s = ActiveSessions(); let h = FakeHistory()
    let r = EventRouter(queue: q, sessions: s, history: h, adapter: FakeAdapter())
    for e in [EventName.preToolUse, .postToolUse, .notification, .userPromptSubmit, .preCompact] {
        let res = await r.route(event: e, request: mkReq("r"))
        #expect(res.stdoutJSON == Data("{}".utf8))
    }
    let snap = await h.snapshot()
    #expect(snap.count == 5)
}
