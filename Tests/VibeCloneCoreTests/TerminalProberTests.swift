import Testing
import Foundation
@testable import VibeCloneCore

@Test func probedTerminal_cases() {
    let all: Set<ProbedTerminal> = [
        .iTerm2, .terminalApp, .ghostty, .warp, .vscode, .cursor,
        .alacritty, .kitty, .tmux, .unknown
    ]
    #expect(all.count == 10)
}

@Test func probe_returns_unknown_when_lineage_has_no_match() {
    let lineage: [pid_t: (ppid: pid_t, comm: String)] = [
        100: (90, "bash"),
        90:  (80, "login"),
        80:  (1, "launchd")
    ]
    let result = TerminalProber.probe(startPid: 100) { pid in lineage[pid] }
    #expect(result == .unknown)
}

@Test func probe_finds_iTerm2_in_lineage() {
    let lineage: [pid_t: (ppid: pid_t, comm: String)] = [
        500: (400, "node"),
        400: (300, "zsh"),
        300: (200, "login"),
        200: (1,   "iTerm2"),
    ]
    let result = TerminalProber.probe(startPid: 500) { pid in lineage[pid] }
    #expect(result == .iTerm2)
}

@Test func probe_finds_tmux_before_host_terminal() {
    let lineage: [pid_t: (ppid: pid_t, comm: String)] = [
        500: (400, "node"),
        400: (300, "zsh"),
        300: (200, "tmux"),
        200: (100, "iTerm2"),
    ]
    let result = TerminalProber.probe(startPid: 500) { pid in lineage[pid] }
    #expect(result == .tmux)
}

@Test func probe_recognizes_each_terminal() {
    let cases: [(String, ProbedTerminal)] = [
        ("iTerm2", .iTerm2),
        ("iTerm.app", .iTerm2),
        ("Terminal", .terminalApp),
        ("ghostty", .ghostty),
        ("Ghostty", .ghostty),
        ("Warp", .warp),
        ("stable", .warp),
        ("Code Helper", .vscode),
        ("Code", .vscode),
        ("Cursor Helper", .cursor),
        ("Cursor", .cursor),
        ("alacritty", .alacritty),
        ("kitty", .kitty),
        ("tmux", .tmux),
    ]
    for (comm, expected) in cases {
        let lineage: [pid_t: (ppid: pid_t, comm: String)] = [
            10: (5, "zsh"),
            5:  (1, comm),
        ]
        let result = TerminalProber.probe(startPid: 10) { lineage[$0] }
        #expect(result == expected, "comm=\(comm)")
    }
}

@Test func probe_caps_walk_depth_to_avoid_infinite_loops() {
    let lineage: [pid_t: (ppid: pid_t, comm: String)] = [
        10: (5, "zsh"),
        5:  (10, "evil"),
    ]
    let result = TerminalProber.probe(startPid: 10) { lineage[$0] }
    #expect(result == .unknown)
}
