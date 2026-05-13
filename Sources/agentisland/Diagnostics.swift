import Foundation
import AppKit
import AgentIslandCore

/// `agentisland --doctor` — print a self-check report and exit. Safe to paste
/// into a GitHub issue (no API keys, no transcript content).
@MainActor
enum Diagnostics {
    static func runIfRequested() -> Bool {
        let args = CommandLine.arguments
        guard args.contains("--doctor") || args.contains("--version") else {
            return false
        }
        if args.contains("--version") {
            print("AgentIsland 0.1.0")
            return true
        }
        report()
        return true
    }

    private static func report() {
        let p = Paths()
        print("AgentIsland --doctor")
        print("==================")
        print("Version:           0.1.0")
        print("macOS:             \(ProcessInfo.processInfo.operatingSystemVersionString)")
        print("Arch:              \(machineArch())")

        print("\nFilesystem:")
        check(p.dotDir.path,           label: "  ~/.agentisland")
        check(p.binDir.path,           label: "  bin/")
        check(p.launcher.path,     label: "  bin/agentisland-bridge")
        check(p.runDir.path,           label: "  run/")
        check(p.socket.path,            label: "  socket")
        check(p.config.path,           label: "  config.json")
        check(p.historyJSONL.path,     label: "  history.jsonl")

        print("\nClaude hooks:")
        let settings = ("\(NSHomeDirectory())/.claude/settings.json")
        check(settings,                label: "  ~/.claude/settings.json")
        let hookCount = countHookEntries(at: URL(fileURLWithPath: settings))
        print("  hook entries:    \(hookCount) (expected 11)")

        print("\nScreens:")
        for s in NSScreen.screens {
            print("  - \(s.localizedName)  frame=\(s.frame)  safeTop=\(s.safeAreaInsets.top)")
        }

        print("\nProcesses:")
        let me = ProcessInfo.processInfo.processIdentifier
        print("  pid:             \(me)")

        print("\nDone. Paste the above (no secrets) when filing a bug.")
    }

    private static func check(_ path: String, label: String) {
        let exists = FileManager.default.fileExists(atPath: path)
        print("\(label): \(exists ? "OK" : "MISSING")  \(path)")
    }

    private static func machineArch() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var buf = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &buf, &size, nil, 0)
        return String(cString: buf)
    }

    private static func countHookEntries(at url: URL) -> Int {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any] else {
            return 0
        }
        var n = 0
        for (_, value) in hooks {
            if let arr = value as? [Any] {
                for entry in arr {
                    if let dict = entry as? [String: Any],
                       let inner = dict["hooks"] as? [Any] {
                        for h in inner {
                            if let hd = h as? [String: Any],
                               let cmd = hd["command"] as? String,
                               cmd.contains("agentisland-bridge") {
                                n += 1
                            }
                        }
                    }
                }
            }
        }
        return n
    }
}
