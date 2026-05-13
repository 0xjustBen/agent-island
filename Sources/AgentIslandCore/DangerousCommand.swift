import Foundation

/// Heuristic detector for destructive shell commands. Used by auto-approve
/// to force a human gate on operations that can lose data or weaken the host.
public enum DangerousCommand {

    /// Return true if `command` looks dangerous and should NOT be auto-approved.
    public static func isDangerous(_ command: String) -> Bool {
        let c = command.lowercased()
        for pat in patterns {
            if c.range(of: pat, options: .regularExpression) != nil { return true }
        }
        return false
    }

    /// Inspect a permission request payload — if the tool is Bash with a
    /// dangerous command, return true.
    public static func isDangerous(payload: [String: JSONValue]) -> Bool {
        guard case .string(let tool) = payload["tool_name"] ?? .null,
              tool == "Bash",
              case .object(let input) = payload["tool_input"] ?? .null,
              case .string(let cmd) = input["command"] ?? .null
        else { return false }
        return isDangerous(cmd)
    }

    /// Regex patterns. Conservative — false positives push to human review,
    /// false negatives let bad commands through.
    private static let patterns: [String] = [
        #"\brm\s+(-[a-z]*r[a-z]*f?|-[a-z]*f[a-z]*r?)\b"#,    // rm -rf / -fr
        #"\brm\s+-r\b"#,                                       // rm -r
        #"\brm\s+/(?!tmp\b)"#,                                 // rm /<root path> (not /tmp)
        #":\s*\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:"#,       // fork bomb
        #"\bdd\s+if=.*of=/dev/"#,                              // dd to a device
        #"\bmkfs\."#,                                          // filesystem reformat
        #"\bshred\b"#,                                         // shred
        #"\bsudo\s+(rm|mv|dd|mkfs|chmod|chown)\b"#,            // sudo destructive
        #">\s*/dev/(sd[a-z]|disk\d|nvme)"#,                    // overwrite raw device
        #"\bchmod\s+-r\s*[0-7]{3}\s+/"#,                       // chmod -R on root
        #"\bchown\s+-r\b.*/"#,                                 // chown -R on a real path
        #"\bcurl\b.*\|\s*(sh|bash|zsh|fish)\b"#,               // curl | sh
        #"\bwget\b.*\|\s*(sh|bash|zsh|fish)\b"#,               // wget | sh
        #"\beval\s+\$\("#,                                     // eval $(…)
        #"\bgit\s+clean\s+-fd"#,                               // git clean -fd
        #"\bgit\s+reset\s+--hard"#,                            // git reset --hard
        #"\bgit\s+push\s+.*--force"#,                          // git push --force
        #"\bgit\s+push\s+.*-f\b"#,                             // git push -f
        #"\bnpm\s+publish\b"#,                                 // npm publish
        #"\bpip\s+uninstall\b"#,                               // pip uninstall (often -y)
        #"\bdrop\s+(table|database|schema)\b"#,                // SQL drop
        #"\btruncate\s+table\b"#,                              // SQL truncate
        #"\bkill(all)?\s+-9\b"#,                               // kill -9
        #"\bdocker\s+system\s+prune\b"#,                       // docker prune
        #"\bdocker\s+volume\s+rm\b"#                           // docker volume rm
    ]
}
