import Foundation
import VibeCloneCore

public enum JSONCMergerError: Error { case parse(String) }

public enum JSONCMerger {

    /// Strip // line and /* */ block comments. String literals + escapes preserved.
    public static func stripComments(_ s: String) -> String {
        var out = ""
        var i = s.startIndex
        var inString = false
        var escape = false
        while i < s.endIndex {
            let c = s[i]
            if inString {
                out.append(c)
                if escape { escape = false }
                else if c == "\\" { escape = true }
                else if c == "\"" { inString = false }
                i = s.index(after: i)
                continue
            }
            if c == "\"" { inString = true; out.append(c); i = s.index(after: i); continue }
            let next = s.index(after: i)
            if c == "/", next < s.endIndex {
                if s[next] == "/" {
                    while i < s.endIndex && s[i] != "\n" { i = s.index(after: i) }
                    continue
                }
                if s[next] == "*" {
                    i = s.index(i, offsetBy: 2)
                    while i < s.endIndex {
                        if s[i] == "*", s.index(after: i) < s.endIndex, s[s.index(after: i)] == "/" {
                            i = s.index(i, offsetBy: 2); break
                        }
                        i = s.index(after: i)
                    }
                    continue
                }
            }
            out.append(c); i = s.index(after: i)
        }
        return out
    }

    public static func hasHook(in original: String, command: String,
                               eventName: String, matcher: String) -> Bool {
        guard let obj = parseObject(original) else { return false }
        guard let hooks = obj["hooks"] as? [String: Any] else { return false }
        guard let entries = hooks[eventName] as? [[String: Any]] else { return false }
        for entry in entries {
            guard (entry["matcher"] as? String) == matcher else { continue }
            guard let inner = entry["hooks"] as? [[String: Any]] else { continue }
            for h in inner where (h["command"] as? String) == command { return true }
        }
        return false
    }

    /// Idempotent merge. Re-parses, mutates the dictionary, re-serializes pretty-printed.
    /// Comments are dropped on output; backup before first edit is the caller's responsibility.
    /// `timeoutSeconds` non-nil → `"timeout": <n>` set on the merged hook entry.
    public static func merge(original: String,
                             ensureHookCommand command: String,
                             eventName: String,
                             matcher: String,
                             timeoutSeconds: Int?) throws -> String {
        var obj = parseObject(original) ?? [:]
        var hooks = (obj["hooks"] as? [String: Any]) ?? [:]
        var entries = (hooks[eventName] as? [[String: Any]]) ?? []

        var idx = entries.firstIndex { ($0["matcher"] as? String) == matcher }
        if idx == nil {
            entries.append(["matcher": matcher, "hooks": [[String: Any]]()])
            idx = entries.count - 1
        }
        var inner = (entries[idx!]["hooks"] as? [[String: Any]]) ?? []
        if !inner.contains(where: { ($0["command"] as? String) == command }) {
            var hookEntry: [String: Any] = ["type": "command", "command": command]
            if let t = timeoutSeconds { hookEntry["timeout"] = t }
            inner.append(hookEntry)
        }
        entries[idx!]["hooks"] = inner
        hooks[eventName] = entries
        obj["hooks"] = hooks

        let data = try JSONSerialization.data(withJSONObject: obj,
            options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private static func parseObject(_ s: String) -> [String: Any]? {
        let stripped = stripComments(s)
        guard let data = stripped.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
