import Testing
import Foundation
@testable import AgentIslandTerminals
@testable import AgentIslandCore

@Test func id_is_iterm2() {
    #expect(ITerm2Jumper().id == "iterm2")
}

@Test func canJump_false_when_iterm2_not_running() async {
    // On CI / headless machines iTerm2 won't be running. Just exercise the code path.
    let j = ITerm2Jumper()
    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: nil)
    _ = await j.canJump(to: loc)
    // Don't assert true/false — depends on host. Test that the call returns without throwing/hanging.
}

@Test func appleScript_template_includes_tty_branch_when_tty_present() {
    let j = ITerm2Jumper()
    let loc = TerminalLocator(tty: "/dev/ttys003", cwd: nil, ppid: nil)
    let script = j._appleScript(for: loc)
    #expect(script.contains("/dev/ttys003"))
    #expect(script.contains("tell application \"iTerm2\""))
    #expect(script.contains("activate"))
}

@Test func appleScript_falls_back_to_activate_when_tty_missing() {
    let j = ITerm2Jumper()
    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: nil)
    let script = j._appleScript(for: loc)
    #expect(script.contains("activate"))
    #expect(!script.contains("if (tty of s) is"))
}
