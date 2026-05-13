import Testing
import Foundation
@testable import AgentIslandCore

@Test func add_and_snapshot() async {
    let s = NoticeStore()
    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: nil)
    await s.add(Notice(id: "1", source: "claude", message: "hello",
                       locator: loc, receivedAt: Date()))
    let snap = await s.snapshot()
    #expect(snap.count == 1)
    #expect(snap[0].message == "hello")
}

@Test func dedup_same_source_and_message() async {
    let s = NoticeStore()
    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: nil)
    await s.add(Notice(id: "1", source: "claude", message: "x", locator: loc, receivedAt: Date()))
    await s.add(Notice(id: "2", source: "claude", message: "x", locator: loc, receivedAt: Date()))
    let snap = await s.snapshot()
    #expect(snap.count == 1)
}

@Test func dismiss_removes_by_id() async {
    let s = NoticeStore()
    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: nil)
    await s.add(Notice(id: "1", source: "claude", message: "a", locator: loc, receivedAt: Date()))
    await s.add(Notice(id: "2", source: "claude", message: "b", locator: loc, receivedAt: Date()))
    await s.dismiss(id: "1")
    let snap = await s.snapshot()
    #expect(snap.count == 1)
    #expect(snap[0].id == "2")
}

@Test func expired_notices_pruned() async {
    let s = NoticeStore(maxAge: 0.1)
    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: nil)
    await s.add(Notice(id: "1", source: "claude", message: "old",
                       locator: loc, receivedAt: Date().addingTimeInterval(-10)))
    try? await Task.sleep(for: .milliseconds(50))
    let snap = await s.snapshot()
    #expect(snap.isEmpty)
}
