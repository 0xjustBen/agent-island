import Foundation
import AppKit
import VibeCloneCore

public struct TerminalAppJumper: TerminalJumper {
    public let id = "terminal-app"
    public init() {}

    public func canJump(to: TerminalLocator) async -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.apple.Terminal"
        }
    }

    public func jump(to locator: TerminalLocator) async throws {
        guard await canJump(to: locator) else {
            throw TerminalJumpError.appNotRunning("Terminal")
        }
        try runAppleScript(_appleScript(for: locator))
        if let url = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.apple.Terminal") {
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = true
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: cfg)
        }
    }

    /// Internal — exposed for testing.
    public func _appleScript(for loc: TerminalLocator) -> String {
        // Terminal.app: windows contain tabs, each tab has a `tty` property.
        if let tty = loc.tty {
            return """
            tell application "Terminal"
                set target_tty to "\(tty)"
                repeat with w in windows
                    repeat with t in tabs of w
                        if tty of t is target_tty then
                            set selected of t to true
                            set frontmost of w to true
                            return
                        end if
                    end repeat
                end repeat
                activate
            end tell
            """
        }
        return """
        tell application "Terminal"
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
