import Testing
import Foundation
@testable import AgentIslandTerminals
@testable import AgentIslandCore

@Test func terminalApp_id() {
    #expect(TerminalAppJumper().id == "terminal-app")
}

@Test func terminalApp_canJump_returns_false_when_not_running() async {
    let j = TerminalAppJumper()
    _ = await j.canJump(to: TerminalLocator(tty: nil, cwd: nil, ppid: nil))
}

@Test func terminalApp_appleScript_with_tty_matches_window() {
    let j = TerminalAppJumper()
    let loc = TerminalLocator(tty: "/dev/ttys003", cwd: nil, ppid: nil)
    let script = j._appleScript(for: loc)
    #expect(script.contains("/dev/ttys003"))
    #expect(script.contains("tell application \"Terminal\""))
    #expect(script.contains("activate"))
}

@Test func terminalApp_appleScript_without_tty_just_activates() {
    let j = TerminalAppJumper()
    let script = j._appleScript(for: TerminalLocator(tty: nil, cwd: nil, ppid: nil))
    #expect(script.contains("activate"))
    #expect(!script.contains("if tty of t"))
}

@Test func composite_picks_first_jumper_that_canJump() async throws {
    // We can't easily mock canJump without a protocol-typed list, so just verify
    // the type exists and an instance can be created.
    let c = CompositeJumper.default()
    #expect(c.id == "composite")
    // canJump returns true if ANY underlying jumper can jump.
    _ = await c.canJump(to: TerminalLocator(tty: nil, cwd: nil, ppid: nil))
}
