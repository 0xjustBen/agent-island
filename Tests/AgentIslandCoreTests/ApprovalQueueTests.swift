import Testing
import Foundation
@testable import AgentIslandCore

private func mkReq(_ id: String, source: String = "claude", cmd: String = "ls") -> PermissionRequest {
    PermissionRequest(
        id: id, source: source,
        payload: ["tool_name": .string("Bash"), "tool_input": .object(["command": .string(cmd)])],
        locator: TerminalLocator(tty: nil, cwd: nil, ppid: nil),
        receivedAt: Date()
    )
}

@Test func enqueue_and_resolve_returns_response() async throws {
    let q = ApprovalQueue(timeout: .seconds(5))
    Task {
        try? await Task.sleep(for: .milliseconds(50))
        await q.resolve(id: "r1", with: ApprovalResponse(decision: .approve))
    }
    let resp = await q.submitAndAwait(mkReq("r1"))
    #expect(resp.decision == .approve)
}

@Test func duplicate_within_window_is_deduplicated() async throws {
    let q = ApprovalQueue(timeout: .seconds(60), dedupWindow: .seconds(5))
    Task {
        try? await Task.sleep(for: .milliseconds(40))
        await q.resolve(id: "r1", with: ApprovalResponse(decision: .approve))
    }
    async let a: ApprovalResponse = q.submitAndAwait(mkReq("r1"))
    async let b: ApprovalResponse = q.submitAndAwait(mkReq("r2"))   // same dedup key (same source+payload)
    let (ra, rb) = await (a, b)
    #expect(ra.decision == .approve)
    #expect(rb.decision == .approve)
}

@Test func timeout_returns_expired() async throws {
    let q = ApprovalQueue(timeout: .milliseconds(50))
    let resp = await q.submitAndAwait(mkReq("r1"))
    #expect(resp.decision == .expired)
}

@Test func pending_count_and_list() async throws {
    let q = ApprovalQueue(timeout: .seconds(5))
    Task {
        try? await Task.sleep(for: .milliseconds(30))
        await q.resolve(id: "r1", with: ApprovalResponse(decision: .deny))
    }
    async let r = q.submitAndAwait(mkReq("r1"))
    try? await Task.sleep(for: .milliseconds(10))
    let count = await q.pendingCount
    let list = await q.pendingList
    #expect(count == 1)
    #expect(list.first?.id == "r1")
    _ = await r
}

@Test func cancel_resolves_with_given_decision() async throws {
    let q = ApprovalQueue(timeout: .seconds(60))
    Task {
        try? await Task.sleep(for: .milliseconds(20))
        await q.cancel(id: "r1", decision: .deny, reason: "user cancelled")
    }
    let resp = await q.submitAndAwait(mkReq("r1"))
    #expect(resp.decision == .deny)
    #expect(resp.reason == "user cancelled")
}
