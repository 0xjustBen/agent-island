import Foundation
import AppKit
import VibeCloneCore

public struct ITerm2Jumper: TerminalJumper {
    public let id = "iterm2"
    public let probedKind: ProbedTerminal = .iTerm2
    public init() {}

    public func canJump(to: TerminalLocator) async -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.googlecode.iterm2"
        }
    }

    public func jump(to locator: TerminalLocator) async throws {
        guard await canJump(to: locator) else {
            throw TerminalJumpError.appNotRunning("iTerm2")
        }
        try runAppleScript(_appleScript(for: locator))
        if let url = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.googlecode.iterm2") {
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = true
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: cfg)
        }
    }

    /// Internal — exposed for testing.
    public func _appleScript(for loc: TerminalLocator) -> String {
        if let tty = loc.tty {
            return """
            tell application "iTerm2"
                set target_tty to "\(tty)"
                repeat with w in windows
                    repeat with t in tabs of w
                        repeat with s in sessions of t
                            if (tty of s) is target_tty then
                                select t
                                tell w to activate
                                return
                            end if
                        end repeat
                    end repeat
                end repeat
                activate
            end tell
            """
        }
        return """
        tell application "iTerm2"
            activate
        end tell
        """
    }

    private func runAppleScript(_ source: String) throws {
        var err: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw TerminalJumpError.noMatchingSession
        }
        _ = script.executeAndReturnError(&err)
        if let e = err {
            if let code = e[NSAppleScript.errorNumber] as? Int, code == -1743 {
                throw TerminalJumpError.automationPermissionDenied
            }
            throw TerminalJumpError.noMatchingSession
        }
    }
}
