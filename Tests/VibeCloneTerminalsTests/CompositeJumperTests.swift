import Testing
import Foundation
@testable import VibeCloneTerminals
@testable import VibeCloneCore

private actor JumpRecorder {
    var jumps: [String] = []
    func record(_ id: String) { jumps.append(id) }
    func snapshot() -> [String] { jumps }
}

private struct MockJumper: TerminalJumper {
    let id: String
    let probedKind: ProbedTerminal
    let canJumpResult: Bool
    let throwsError: Bool
    let recorder: JumpRecorder

    func canJump(to: TerminalLocator) async -> Bool { canJumpResult }
    func jump(to: TerminalLocator) async throws {
        await recorder.record(id)
        if throwsError { throw TerminalJumpError.noMatchingSession }
    }
}

@Test func prober_match_runs_preferred_first() async throws {
    let rec = JumpRecorder()
    let composite = CompositeJumper(jumpers: [
        MockJumper(id: "iterm",   probedKind: .iTerm2,      canJumpResult: true, throwsError: false, recorder: rec),
        MockJumper(id: "kitty",   probedKind: .kitty,       canJumpResult: true, throwsError: false, recorder: rec),
        MockJumper(id: "term",    probedKind: .terminalApp, canJumpResult: true, throwsError: false, recorder: rec),
    ], prober: { _ in .kitty })

    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: 100)
    try await composite.jump(to: loc)
    let snap = await rec.snapshot()
    #expect(snap == ["kitty"])
}

@Test func prober_miss_falls_back_to_iteration() async throws {
    let rec = JumpRecorder()
    let composite = CompositeJumper(jumpers: [
        MockJumper(id: "iterm", probedKind: .iTerm2, canJumpResult: false, throwsError: false, recorder: rec),
        MockJumper(id: "term",  probedKind: .terminalApp, canJumpResult: true, throwsError: false, recorder: rec),
    ], prober: { _ in .ghostty })   // no ghostty in jumpers

    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: 100)
    try await composite.jump(to: loc)
    let snap = await rec.snapshot()
    #expect(snap == ["term"])
}

@Test func prober_throwing_falls_back_to_iteration() async throws {
    let rec = JumpRecorder()
    let composite = CompositeJumper(jumpers: [
        MockJumper(id: "iterm", probedKind: .iTerm2, canJumpResult: true, throwsError: true, recorder: rec),
        MockJumper(id: "term",  probedKind: .terminalApp, canJumpResult: true, throwsError: false, recorder: rec),
    ], prober: { _ in .iTerm2 })

    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: 100)
    try await composite.jump(to: loc)
    let snap = await rec.snapshot()
    #expect(snap == ["iterm", "term"])
}

@Test func no_prober_uses_iteration_only() async throws {
    let rec = JumpRecorder()
    let composite = CompositeJumper(jumpers: [
        MockJumper(id: "iterm", probedKind: .iTerm2, canJumpResult: true, throwsError: false, recorder: rec),
        MockJumper(id: "term",  probedKind: .terminalApp, canJumpResult: true, throwsError: false, recorder: rec),
    ], prober: nil)

    let loc = TerminalLocator(tty: nil, cwd: nil, ppid: 100)
    try await composite.jump(to: loc)
    let snap = await rec.snapshot()
    #expect(snap == ["iterm"])
}
