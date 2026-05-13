import Foundation
import AppKit
import VibeCloneCore

public struct CursorJumper: TerminalJumper {
    public let id = "cursor"
    public let probedKind: ProbedTerminal = .cursor
    public init() {}

    public func canJump(to: TerminalLocator) async -> Bool {
        AppKitActivate.isRunning(bundleId: "com.todesktop.230313mzl4w4u92")
    }

    public func jump(to locator: TerminalLocator) async throws {
        guard await canJump(to: locator) else { throw TerminalJumpError.appNotRunning("Cursor") }
        try? AppKitActivate.runAppleScript(#"""
        tell application "Cursor"
            activate
        end tell
        """#)
        try await AppKitActivate.activate(bundleId: "com.todesktop.230313mzl4w4u92")

        if let cwd = locator.cwd, let bin = findCursorBinary() {
            let proc = Process()
            proc.executableURL = bin
            proc.arguments = ["--reuse-window", cwd]
            try? proc.run()
        }
    }

    private func findCursorBinary() -> URL? {
        let candidates = [
            "/usr/local/bin/cursor",
            "/opt/homebrew/bin/cursor",
            "/Applications/Cursor.app/Contents/Resources/app/bin/cursor",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
