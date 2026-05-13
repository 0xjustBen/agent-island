import Testing
import Foundation
@testable import VibeCloneCore

@Test func agentBranding_known_source() {
    let b = AgentBranding.brand(for: "claude")
    #expect(b.displayName == "Claude")
    #expect(b.emoji == "👻")
    #expect(b.accentHex == "#34c759")
}

@Test func agentBranding_unknown_source_fallback() {
    let b = AgentBranding.brand(for: "newllm")
    #expect(b.displayName == "Newllm")
    #expect(b.emoji == "💻")
}

@Test func terminalBranding_each_kind() {
    #expect(TerminalBranding.displayName(for: .iTerm2) == "iTerm")
    #expect(TerminalBranding.displayName(for: .ghostty) == "Ghostty")
    #expect(TerminalBranding.displayName(for: .tmux) == "tmux")
    #expect(TerminalBranding.displayName(for: .unknown) == "Terminal")
}

@Test func timeAgo_thresholds() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    #expect(TimeAgo.format(now.addingTimeInterval(-3), relativeTo: now) == "now")
    #expect(TimeAgo.format(now.addingTimeInterval(-15), relativeTo: now) == "15s")
    #expect(TimeAgo.format(now.addingTimeInterval(-90), relativeTo: now) == "1m")
    #expect(TimeAgo.format(now.addingTimeInterval(-1700), relativeTo: now) == "28m")
    #expect(TimeAgo.format(now.addingTimeInterval(-3700), relativeTo: now) == "1h")
    #expect(TimeAgo.format(now.addingTimeInterval(-18000), relativeTo: now) == "5h")
    #expect(TimeAgo.format(now.addingTimeInterval(-90000), relativeTo: now) == "1d")
}

@Test func askOptionParser_numbered_dot() {
    let msg = """
    Which deployment target?
    1. Production
    2. Staging
    3. Local only
    """
    let r = AskOptionParser.parse(msg)!
    #expect(r.question == "Which deployment target?")
    #expect(r.options.count == 3)
    #expect(r.options[0].number == 1)
    #expect(r.options[0].label == "Production")
    #expect(r.options[2].label == "Local only")
}

@Test func askOptionParser_numbered_paren() {
    let msg = """
    Pick one:
    1) Yes
    2) No
    """
    let r = AskOptionParser.parse(msg)!
    #expect(r.options.count == 2)
    #expect(r.options[1].label == "No")
}

@Test func askOptionParser_plain_text_returns_nil() {
    let r = AskOptionParser.parse("Just a notification, no options.")
    #expect(r == nil)
}

@Test func askOptionParser_single_numbered_line_returns_nil() {
    // Need at least 2 to be considered "options".
    let r = AskOptionParser.parse("1. Only one")
    #expect(r == nil)
}

@Test func textDiffer_simple_edit() {
    let old = "line 1\nline 2\nline 3"
    let new = "line 1\nline 2 modified\nline 3"
    let d = TextDiffer.diff(old: old, new: new)
    let stats = TextDiffer.stats(d)
    #expect(stats.added == 1)
    #expect(stats.removed == 1)
    let hasRemoved = d.contains { if case .removed(let s) = $0 { return s == "line 2" }; return false }
    let hasAdded   = d.contains { if case .added(let s)   = $0 { return s == "line 2 modified" }; return false }
    #expect(hasRemoved)
    #expect(hasAdded)
}

@Test func textDiffer_pure_addition() {
    let d = TextDiffer.diff(old: "a\nb", new: "a\nb\nc")
    let s = TextDiffer.stats(d)
    #expect(s.added == 1)
    #expect(s.removed == 0)
}

@Test func textDiffer_pure_removal() {
    let d = TextDiffer.diff(old: "a\nb\nc", new: "a\nc")
    let s = TextDiffer.stats(d)
    #expect(s.added == 0)
    #expect(s.removed == 1)
}

@Test func textDiffer_identical_no_changes() {
    let d = TextDiffer.diff(old: "same\ntext", new: "same\ntext")
    let s = TextDiffer.stats(d)
    #expect(s.added == 0)
    #expect(s.removed == 0)
}
