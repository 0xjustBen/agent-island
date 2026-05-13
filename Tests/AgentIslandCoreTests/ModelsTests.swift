import Testing
import Foundation
@testable import AgentIslandCore

@Test func eventName_covers_all_11_claude_code_events() {
    let names: Set<EventName> = [.preToolUse, .postToolUse, .permissionRequest, .notification,
        .userPromptSubmit, .sessionStart, .sessionEnd, .stop, .subagentStart, .subagentStop, .preCompact]
    #expect(names.count == 11)
    #expect(EventName(rawValue: "PreToolUse") == .preToolUse)
    #expect(EventName.permissionRequest.timeoutSeconds == 86400)
    #expect(EventName.preToolUse.matcher == "*")
    #expect(EventName.sessionStart.matcher == "")
    #expect(EventName.allCases.count == 11)
}

@Test func permissionRequest_roundTrip() throws {
    let r = PermissionRequest(id: "x", source: "claude",
        payload: ["tool_name": .string("Bash")],
        locator: TerminalLocator(tty: "/dev/ttys0", cwd: "/", ppid: 1),
        receivedAt: Date(timeIntervalSince1970: 100))
    let data = try JSONEncoder().encode(r)
    let back = try JSONDecoder().decode(PermissionRequest.self, from: data)
    #expect(back.id == "x")
    #expect(back.source == "claude")
    #expect(back.locator.ppid == 1)
}

@Test func approvalDecision_raw_values() {
    #expect(ApprovalDecision.approve.rawValue == "approve")
    #expect(ApprovalDecision.deny.rawValue == "deny")
    #expect(ApprovalDecision.expired.rawValue == "expired")
    #expect(ApprovalDecision.error.rawValue == "error")
}

@Test func jsonValue_roundTrips_nested_object() throws {
    let v = JSONValue.object([
        "a": .string("hi"),
        "b": .number(42),
        "c": .bool(true),
        "d": .null,
        "e": .array([.string("x"), .number(1)])
    ])
    let data = try JSONEncoder().encode(v)
    let back = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(back == v)
}
