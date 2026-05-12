import Testing
import Foundation
@testable import VibeCloneAdapters
@testable import VibeCloneCore

private let EXPECTED_CMD = #"/bin/sh -c '[ -x "$HOME/.vibeclone/bin/vibeclone-bridge" ] && "$HOME/.vibeclone/bin/vibeclone-bridge" --source claude; exit 0'"#

@Test func adapter_metadata() {
    let a = ClaudeCodeAdapter()
    #expect(a.id == "claude-code")
    #expect(a.displayName == "Claude Code")
    #expect(a.sourceFlag == "claude")
    #expect(a.ipcKind == .stdinStdout)
    #expect(a.hookCommand == EXPECTED_CMD)
}

@Test func installs_all_11_events() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    let paths = Paths(home: tmp)
    try paths.ensureAll()
    try FileManager.default.createDirectory(at: paths.claudeDir, withIntermediateDirectories: true)
    try "{}".write(to: paths.claudeSettings, atomically: true, encoding: .utf8)

    try ClaudeCodeAdapter().installHooks(paths: paths)
    let merged = try String(contentsOf: paths.claudeSettings)

    // EXPECTED_CMD has literal `"` chars; in JSON storage they're escaped as `\"`.
    let expectedInJSON = EXPECTED_CMD.replacingOccurrences(of: "\"", with: "\\\"")
    #expect(merged.contains(expectedInJSON))
    let typeCount = merged.components(separatedBy: "\"type\"").count - 1
    #expect(typeCount == 11)

    let json = try JSONSerialization.jsonObject(with: Data(merged.utf8)) as! [String: Any]
    let hooks = json["hooks"] as! [String: Any]
    let perm = hooks["PermissionRequest"] as! [[String: Any]]
    let permHook = (perm[0]["hooks"] as! [[String: Any]])[0]
    #expect(permHook["timeout"] as? Int == 86400)
}

@Test func heal_returns_false_when_all_present() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    let paths = Paths(home: tmp)
    try paths.ensureAll()
    try FileManager.default.createDirectory(at: paths.claudeDir, withIntermediateDirectories: true)
    try "{}".write(to: paths.claudeSettings, atomically: true, encoding: .utf8)
    let a = ClaudeCodeAdapter()
    try a.installHooks(paths: paths)
    let healed = try a.healHooks(paths: paths)
    #expect(healed == false)
}

@Test func heal_returns_true_when_user_strips_a_hook() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    let paths = Paths(home: tmp)
    try paths.ensureAll()
    try FileManager.default.createDirectory(at: paths.claudeDir, withIntermediateDirectories: true)
    try "{}".write(to: paths.claudeSettings, atomically: true, encoding: .utf8)
    let a = ClaudeCodeAdapter()
    try a.installHooks(paths: paths)
    // Wipe settings.
    try "{}".write(to: paths.claudeSettings, atomically: true, encoding: .utf8)
    let healed = try a.healHooks(paths: paths)
    #expect(healed == true)
    let merged = try String(contentsOf: paths.claudeSettings)
    // EXPECTED_CMD has literal `"` chars; in JSON storage they're escaped as `\"`.
    let expectedInJSON = EXPECTED_CMD.replacingOccurrences(of: "\"", with: "\\\"")
    #expect(merged.contains(expectedInJSON))
}

@Test func backup_made_on_first_edit_only() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    let paths = Paths(home: tmp)
    try paths.ensureAll()
    try FileManager.default.createDirectory(at: paths.claudeDir, withIntermediateDirectories: true)
    let original = "{\"existing\": true}"
    try original.write(to: paths.claudeSettings, atomically: true, encoding: .utf8)
    try ClaudeCodeAdapter().installHooks(paths: paths)
    let backupContent = try String(contentsOf: paths.claudeSettingsBackup)
    #expect(backupContent == original)
    // Second install: backup should NOT be overwritten (still the pristine original).
    try ClaudeCodeAdapter().installHooks(paths: paths)
    let backupContent2 = try String(contentsOf: paths.claudeSettingsBackup)
    #expect(backupContent2 == original)
}

@Test func decodeStdin_extracts_event() throws {
    let url = Bundle.module.url(forResource: "cc-permissionrequest", withExtension: "json")!
    let data = try Data(contentsOf: url)
    let (event, payload) = try ClaudeCodeAdapter().decodeStdin(data)
    #expect(event == .permissionRequest)
    if case .string(let name) = payload["tool_name"] { #expect(name == "Bash") }
    else { Issue.record("tool_name missing") }
}

@Test func decodeStdin_defaults_to_preToolUse_when_event_missing() throws {
    let raw = Data("{\"tool_name\":\"Bash\"}".utf8)
    let (event, _) = try ClaudeCodeAdapter().decodeStdin(raw)
    #expect(event == .preToolUse)
}

@Test func encodeStdoutBody_permission_allow() throws {
    let body = try ClaudeCodeAdapter().encodeStdoutBody(
        event: .permissionRequest, decision: .approve, reason: nil)
    let obj = try JSONSerialization.jsonObject(with: body) as! [String: Any]
    let inner = obj["hookSpecificOutput"] as! [String: Any]
    #expect(inner["hookEventName"] as? String == "PermissionRequest")
    #expect(inner["permissionDecision"] as? String == "allow")
}

@Test func encodeStdoutBody_permission_deny_with_reason() throws {
    let body = try ClaudeCodeAdapter().encodeStdoutBody(
        event: .permissionRequest, decision: .deny, reason: "user denied")
    let obj = try JSONSerialization.jsonObject(with: body) as! [String: Any]
    let inner = obj["hookSpecificOutput"] as! [String: Any]
    #expect(inner["permissionDecision"] as? String == "deny")
    #expect(inner["permissionDecisionReason"] as? String == "user denied")
}

@Test func encodeStdoutBody_non_permission_is_empty_object() throws {
    let body = try ClaudeCodeAdapter().encodeStdoutBody(
        event: .postToolUse, decision: nil, reason: nil)
    #expect(body == Data("{}".utf8))
}
