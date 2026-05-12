import Testing
import Foundation
@testable import VibeCloneAdapters
@testable import VibeCloneCore

@Test func mergeIntoEmpty_addsEntry() throws {
    let url = Bundle.module.url(forResource: "settings-empty", withExtension: "json")!
    let original = try String(contentsOf: url)
    let merged = try JSONCMerger.merge(
        original: original,
        ensureHookCommand: "/Applications/VibeClone.app/Contents/MacOS/vibeclone-bridge --source claude",
        eventName: "PreToolUse",
        matcher: "*",
        timeoutSeconds: nil
    )
    #expect(merged.contains("vibeclone-bridge"))
    #expect(merged.contains("\"PreToolUse\""))
    let data = JSONCMerger.stripComments(merged).data(using: .utf8)!
    let reparsed = try JSONSerialization.jsonObject(with: data)
    #expect(reparsed is [String: Any])
}

@Test func mergePreservesExistingHooks() throws {
    let url = Bundle.module.url(forResource: "settings-with-existing-hooks", withExtension: "json")!
    let original = try String(contentsOf: url)
    let merged = try JSONCMerger.merge(
        original: original,
        ensureHookCommand: "/path/vibeclone-bridge --source claude",
        eventName: "PreToolUse", matcher: "*", timeoutSeconds: nil
    )
    #expect(merged.contains("other-tool"))            // preserved
    #expect(merged.contains("vibeclone-bridge"))      // added
}

@Test func mergeIsIdempotent() throws {
    let url = Bundle.module.url(forResource: "settings-empty", withExtension: "json")!
    let original = try String(contentsOf: url)
    let cmd = "/p/vibeclone-bridge --source claude"
    let once = try JSONCMerger.merge(original: original, ensureHookCommand: cmd,
        eventName: "PreToolUse", matcher: "*", timeoutSeconds: nil)
    let twice = try JSONCMerger.merge(original: once, ensureHookCommand: cmd,
        eventName: "PreToolUse", matcher: "*", timeoutSeconds: nil)
    let count = twice.components(separatedBy: "vibeclone-bridge").count - 1
    #expect(count == 1)
}

@Test func mergeAllEvents_installs_11_entries_with_permission_timeout() throws {
    var s = "{}"
    let cmd = "/bin/sh -c '[ -x \"$HOME/.vibeclone/bin/vibeclone-bridge\" ] && \"$HOME/.vibeclone/bin/vibeclone-bridge\" --source claude; exit 0'"
    for event in EventName.allCases {
        s = try JSONCMerger.merge(original: s,
            ensureHookCommand: cmd,
            eventName: event.rawValue,
            matcher: event.matcher,
            timeoutSeconds: event.timeoutSeconds)
    }
    // Command literal contains "vibeclone-bridge" twice; count hook entries via "type" key instead.
    let count = s.components(separatedBy: "\"type\"").count - 1
    #expect(count == 11)
    #expect(s.contains("86400"))                       // PermissionRequest timeout
}

@Test func hasHook_detectsExisting() throws {
    let s = """
    { "hooks": { "PreToolUse": [
        { "matcher": "*", "hooks": [{ "type": "command", "command": "/p/vibeclone-bridge --source claude" }] }
    ]}}
    """
    #expect(JSONCMerger.hasHook(in: s, command: "/p/vibeclone-bridge --source claude",
                                eventName: "PreToolUse", matcher: "*"))
}

@Test func stripComments_handles_line_and_block_and_string_escapes() {
    let input = """
    // top comment
    {
      "a": "// not a comment",
      /* block
         comment */
      "b": 1
    }
    """
    let stripped = JSONCMerger.stripComments(input)
    #expect(!stripped.contains("// top comment"))
    #expect(!stripped.contains("/* block"))
    #expect(stripped.contains("// not a comment"))    // inside string preserved
}
