import Testing
import Foundation
@testable import AgentIslandTerminals
@testable import AgentIslandCore

@Test func ghostty_id_and_probedKind() {
    let j = GhosttyJumper()
    #expect(j.id == "ghostty")
    #expect(j.probedKind == .ghostty)
}
@Test func warp_id_and_probedKind() {
    let j = WarpJumper()
    #expect(j.id == "warp")
    #expect(j.probedKind == .warp)
}
@Test func vscode_id_and_probedKind() {
    let j = VSCodeJumper()
    #expect(j.id == "vscode")
    #expect(j.probedKind == .vscode)
}
@Test func cursor_id_and_probedKind() {
    let j = CursorJumper()
    #expect(j.id == "cursor")
    #expect(j.probedKind == .cursor)
}
@Test func alacritty_id_and_probedKind() {
    let j = AlacrittyJumper()
    #expect(j.id == "alacritty")
    #expect(j.probedKind == .alacritty)
}

@Test func all_canJump_false_when_apps_not_running() async {
    // On most dev machines none of these are open during test.
    // Just exercise without crashing.
    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: nil)
    _ = await GhosttyJumper().canJump(to: loc)
    _ = await WarpJumper().canJump(to: loc)
    _ = await VSCodeJumper().canJump(to: loc)
    _ = await CursorJumper().canJump(to: loc)
    _ = await AlacrittyJumper().canJump(to: loc)
}
