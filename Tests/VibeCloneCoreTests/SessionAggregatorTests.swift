import Testing
import Foundation
@testable import VibeCloneCore

private func mkRequest(_ sid: String, source: String = "claude",
                       payload: [String: JSONValue] = [:],
                       ppid: Int32? = 100) -> PermissionRequest {
    var p = payload
    p["session_id"] = .string(sid)
    return PermissionRequest(
        id: UUID().uuidString, source: source, payload: p,
        locator: TerminalLocator(tty: "/dev/ttys0", cwd: "/tmp", ppid: ppid),
        receivedAt: Date()
    )
}

@Test func sessionStart_creates_card() async {
    let agg = SessionAggregator(probe: { _ in .iTerm2 })
    await agg.accept(event: .sessionStart, request: mkRequest("s1"))
    let snap = await agg.snapshot()
    #expect(snap.count == 1)
    #expect(snap[0].id == "s1")
    #expect(snap[0].source == "claude")
    #expect(snap[0].terminalKind == .iTerm2)
    #expect(snap[0].activity == .idle)
}

@Test func userPromptSubmit_sets_title_and_lastPrompt() async {
    let agg = SessionAggregator(probe: { _ in .iTerm2 })
    await agg.accept(event: .sessionStart, request: mkRequest("s1"))
    let prompt = "fix the auth bug in middleware"
    await agg.accept(event: .userPromptSubmit,
                     request: mkRequest("s1", payload: ["prompt": .string(prompt)]))
    let snap = await agg.snapshot()
    #expect(snap[0].title == prompt)
    #expect(snap[0].lastPrompt == prompt)
}

@Test func preToolUse_for_Edit_sets_activity_description() async {
    let agg = SessionAggregator(probe: { _ in .iTerm2 })
    await agg.accept(event: .sessionStart, request: mkRequest("s1"))
    await agg.accept(event: .preToolUse, request: mkRequest("s1", payload: [
        "tool_name": .string("Edit"),
        "tool_input": .object(["file_path": .string("/src/auth/middleware.ts")])
    ]))
    let snap = await agg.snapshot()
    if case .runningTool(let n, let desc) = snap[0].activity {
        #expect(n == "Edit")
        #expect(desc == "Editing middleware.ts")
    } else { Issue.record("expected runningTool, got \(snap[0].activity)") }
}

@Test func postToolUse_transitions_to_justFinished() async {
    let agg = SessionAggregator(probe: { _ in .iTerm2 })
    await agg.accept(event: .sessionStart, request: mkRequest("s1"))
    await agg.accept(event: .preToolUse, request: mkRequest("s1", payload: [
        "tool_name": .string("Bash")
    ]))
    await agg.accept(event: .postToolUse, request: mkRequest("s1", payload: [
        "tool_name": .string("Bash")
    ]))
    let snap = await agg.snapshot()
    if case .justFinished(let t) = snap[0].activity {
        #expect(t == "Bash")
    } else { Issue.record("expected justFinished") }
}

@Test func sessionEnd_removes_card() async {
    let agg = SessionAggregator(probe: { _ in .iTerm2 })
    await agg.accept(event: .sessionStart, request: mkRequest("s1"))
    await agg.accept(event: .sessionEnd, request: mkRequest("s1"))
    let snap = await agg.snapshot()
    #expect(snap.isEmpty)
}

@Test func permissionRequest_sets_pending() async {
    let agg = SessionAggregator(probe: { _ in .iTerm2 })
    await agg.accept(event: .sessionStart, request: mkRequest("s1"))
    let req = mkRequest("s1", payload: ["tool_name": .string("Edit")])
    await agg.accept(event: .permissionRequest, request: req)
    let snap = await agg.snapshot()
    #expect(snap[0].pendingPermission?.id == req.id)
}

@Test func notification_with_notice_sets_pendingNotice() async {
    let agg = SessionAggregator(probe: { _ in .iTerm2 })
    await agg.accept(event: .sessionStart, request: mkRequest("s1"))
    let notice = Notice(id: "n1", source: "claude", message: "Pick one",
                        locator: TerminalLocator(tty: nil, cwd: nil, ppid: nil),
                        receivedAt: Date())
    await agg.accept(event: .notification, request: mkRequest("s1"), notice: notice)
    let snap = await agg.snapshot()
    #expect(snap[0].pendingNotice?.id == "n1")
}

@Test func clearPendingPermission_clears_it() async {
    let agg = SessionAggregator(probe: { _ in .iTerm2 })
    await agg.accept(event: .sessionStart, request: mkRequest("s1"))
    await agg.accept(event: .permissionRequest, request: mkRequest("s1"))
    await agg.clearPendingPermission(sessionId: "s1")
    let snap = await agg.snapshot()
    #expect(snap[0].pendingPermission == nil)
}

@Test func snapshot_sorted_by_lastActiveAt_descending() async {
    let agg = SessionAggregator(probe: { _ in .iTerm2 })
    await agg.accept(event: .sessionStart, request: mkRequest("a"))
    try? await Task.sleep(for: .milliseconds(10))
    await agg.accept(event: .sessionStart, request: mkRequest("b"))
    let snap = await agg.snapshot()
    #expect(snap.count == 2)
    #expect(snap[0].id == "b")        // most recent first
    #expect(snap[1].id == "a")
}

@Test func ageActivities_demotes_justFinished_to_idle() async throws {
    let agg = SessionAggregator(probe: { _ in .iTerm2 })
    await agg.accept(event: .sessionStart, request: mkRequest("s1"))
    await agg.accept(event: .postToolUse, request: mkRequest("s1", payload: [
        "tool_name": .string("Bash")
    ]))
    try await Task.sleep(for: .milliseconds(60))
    await agg.ageActivities(cooldownSeconds: 0.05)
    let snap = await agg.snapshot()
    #expect(snap[0].activity == .idle)
}
