import Testing
import Foundation
@testable import VibeCloneCore

@Test func tracks_session_open_close_and_subagent_depth() async {
    let s = ActiveSessions()
    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: nil)
    await s.start(sessionId: "a", source: "claude", locator: loc)
    await s.subagentDelta(sessionId: "a", delta: +1)
    await s.subagentDelta(sessionId: "a", delta: +1)
    let depth = await s.subagentDepth(sessionId: "a")
    #expect(depth == 2)
    await s.subagentDelta(sessionId: "a", delta: -1)
    let depth2 = await s.subagentDepth(sessionId: "a")
    #expect(depth2 == 1)
    await s.end(sessionId: "a")
    let n = await s.activeCount
    #expect(n == 0)
}

@Test func multiple_sessions_tracked_independently() async {
    let s = ActiveSessions()
    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: nil)
    await s.start(sessionId: "a", source: "claude", locator: loc)
    await s.start(sessionId: "b", source: "codex", locator: loc)
    let n = await s.activeCount
    #expect(n == 2)
    let all = await s.all
    #expect(Set(all.map(\.sessionId)) == ["a", "b"])
}

@Test func depth_on_unknown_session_returns_zero() async {
    let s = ActiveSessions()
    let d = await s.subagentDepth(sessionId: "missing")
    #expect(d == 0)
}
