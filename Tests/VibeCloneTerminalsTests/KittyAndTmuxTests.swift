import Testing
import Foundation
@testable import VibeCloneTerminals
@testable import VibeCloneCore

@Test func kitty_id_and_probedKind() {
    let j = KittyJumper()
    #expect(j.id == "kitty")
    #expect(j.probedKind == .kitty)
}

@Test func kitty_command_with_tty() {
    let cmd = KittyJumper()._command(for: TerminalLocator(tty: "/dev/ttys003", cwd: nil, ppid: nil))
    #expect(cmd == ["@", "focus-window", "--match", "tty:/dev/ttys003"])
}

@Test func kitty_command_nil_without_tty() {
    let cmd = KittyJumper()._command(for: TerminalLocator(tty: nil, cwd: nil, ppid: nil))
    #expect(cmd == nil)
}

@Test func tmux_id_and_probedKind() {
    let j = TmuxJumper(hostJumpers: [])
    #expect(j.id == "tmux")
    #expect(j.probedKind == .tmux)
}

@Test func tmux_pickPaneTarget_matches_tty() {
    let listOutput = """
    /dev/ttys001 main:0.0
    /dev/ttys002 main:0.1
    /dev/ttys003 work:1.0
    """
    let j = TmuxJumper(hostJumpers: [])
    #expect(j._pickPaneTarget(from: listOutput, tty: "/dev/ttys003") == "work:1.0")
    #expect(j._pickPaneTarget(from: listOutput, tty: "/dev/ttys002") == "main:0.1")
    #expect(j._pickPaneTarget(from: listOutput, tty: "/dev/ttys999") == nil)
}

@Test func tmux_pickPaneTarget_handles_empty_output() {
    let j = TmuxJumper(hostJumpers: [])
    #expect(j._pickPaneTarget(from: "", tty: "/dev/ttys001") == nil)
}
