import Foundation
import VibeCloneCore

public struct ClaudeCodeAdapter: AgentAdapter {
    public let id          = "claude-code"
    public let displayName = "Claude Code"
    public let sourceFlag  = "claude"
    public let ipcKind: IPCKind = .stdinStdout

    public init() {}

    /// Exact command installed for every hook event. Captured verbatim from
    /// Vibe Island v1.0.33 settings.json, namespace-renamed.
    public var hookCommand: String {
        #"/bin/sh -c '[ -x "$HOME/.vibeclone/bin/vibeclone-bridge" ] && "$HOME/.vibeclone/bin/vibeclone-bridge" --source claude; exit 0'"#
    }

    public func installHooks(paths: Paths) throws {
        try FileManager.default.createDirectory(at: paths.claudeDir,
                                                withIntermediateDirectories: true)
        try writeMerged(paths: paths)
    }

    @discardableResult
    public func healHooks(paths: Paths) throws -> Bool {
        let original = (try? String(contentsOf: paths.claudeSettings)) ?? "{}"
        var missing = false
        for event in EventName.allCases {
            if !JSONCMerger.hasHook(in: original, command: hookCommand,
                                    eventName: event.rawValue, matcher: event.matcher) {
                missing = true; break
            }
        }
        if missing { try writeMerged(paths: paths) }
        return missing
    }

    public func decodeStdin(_ raw: Data) throws -> (event: EventName, payload: [String: JSONValue]) {
        guard let obj = try JSONSerialization.jsonObject(with: raw) as? [String: Any] else {
            throw AdapterError.malformed("not an object")
        }
        let name = (obj["hook_event_name"] as? String) ?? "PreToolUse"
        let event = EventName(rawValue: name) ?? .preToolUse
        let payload = JSONValueWire.wrapObject(obj)
        return (event, payload)
    }

    public func encodeStdoutBody(event: EventName,
                                 decision: ApprovalDecision?,
                                 reason: String?) throws -> Data {
        // Permission gating runs through PreToolUse (CC's real hook).
        // PermissionRequest kept as alias for legacy/tests.
        let hookName: String
        switch event {
        case .preToolUse:        hookName = "PreToolUse"
        case .permissionRequest: hookName = "PermissionRequest"
        default:                 return Data("{}".utf8)
        }
        guard let decision else { return Data("{}".utf8) }
        let decisionStr: String = (decision == .approve) ? "allow" : "deny"
        var inner: [String: Any] = [
            "hookEventName": hookName,
            "permissionDecision": decisionStr
        ]
        if let r = reason { inner["permissionDecisionReason"] = r }
        return try JSONSerialization.data(withJSONObject: ["hookSpecificOutput": inner],
                                          options: [.sortedKeys])
    }

    public enum AdapterError: Error { case malformed(String) }

    // MARK: - Internal

    private func writeMerged(paths: Paths) throws {
        let original = (try? String(contentsOf: paths.claudeSettings)) ?? "{}"
        if !FileManager.default.fileExists(atPath: paths.claudeSettingsBackup.path),
           FileManager.default.fileExists(atPath: paths.claudeSettings.path) {
            try? FileManager.default.copyItem(at: paths.claudeSettings,
                                              to: paths.claudeSettingsBackup)
        }
        var merged = original
        for event in EventName.allCases {
            merged = try JSONCMerger.merge(
                original: merged,
                ensureHookCommand: hookCommand,
                eventName: event.rawValue,
                matcher: event.matcher,
                timeoutSeconds: event.timeoutSeconds
            )
        }
        // JSONSerialization escapes "/" as "\/"; reverse that so the command
        // text appears verbatim in the file (matches what users see and what
        // tests / heal-checks grep for).
        merged = merged.replacingOccurrences(of: "\\/", with: "/")
        let tmp = paths.claudeSettings.appendingPathExtension("tmp.\(UUID().uuidString)")
        try merged.write(to: tmp, atomically: true, encoding: .utf8)
        _ = try FileManager.default.replaceItemAt(paths.claudeSettings, withItemAt: tmp)
    }
}
