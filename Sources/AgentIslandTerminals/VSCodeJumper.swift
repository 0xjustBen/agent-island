import Foundation
import AppKit
import AgentIslandCore

public struct VSCodeJumper: TerminalJumper {
    public let id = "vscode"
    public let probedKind: ProbedTerminal = .vscode
    public init() {}

    public func canJump(to: TerminalLocator) async -> Bool {
        AppKitActivate.isRunning(bundleId: "com.microsoft.VSCode")
    }

    public func jump(to locator: TerminalLocator) async throws {
        guard await canJump(to: locator) else { throw TerminalJumpError.appNotRunning("VS Code") }
        try? AppKitActivate.runAppleScript(#"""
        tell application "Visual Studio Code"
            activate
        end tell
        """#)
        try await AppKitActivate.activate(bundleId: "com.microsoft.VSCode")

        // Best-effort: focus the window with matching cwd via `code` CLI.
        if let cwd = locator.cwd, let codeBinary = findCodeBinary() {
            let proc = Process()
            proc.executableURL = codeBinary
            proc.arguments = ["--reuse-window", cwd]
            try? proc.run()
        }
    }

    private func findCodeBinary() -> URL? {
        let candidates = [
            "/usr/local/bin/code",
            "/opt/homebrew/bin/code",
            "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
