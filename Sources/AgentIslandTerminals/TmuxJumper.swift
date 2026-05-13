import Foundation
import AgentIslandCore

/// tmux runs INSIDE a host terminal. Jump = two steps:
///   1. `tmux select-pane -t <session:window.pane>` to switch within the
///      multiplexer to the right pane (matched by tty).
///   2. Delegate host-terminal activation to a sibling jumper list.
public struct TmuxJumper: TerminalJumper {
    public let id = "tmux"
    public let probedKind: ProbedTerminal = .tmux

    /// Host jumpers for step 2 (typically iTerm2, Terminal.app, Ghostty, etc.).
    /// Excludes TmuxJumper itself to avoid recursion.
    public let hostJumpers: [any TerminalJumper]

    public init(hostJumpers: [any TerminalJumper]) {
        self.hostJumpers = hostJumpers
    }

    public func canJump(to: TerminalLocator) async -> Bool {
        // tmux jump is meaningful when we can run `tmux list-panes`.
        findTmuxBinary() != nil
    }

    public func jump(to locator: TerminalLocator) async throws {
        if let tty = locator.tty, let target = pickPaneTarget(for: tty) {
            _ = try? runTmux(args: ["select-pane", "-t", target])
        }
        // Step 2: delegate to first host jumper that canJump.
        for j in hostJumpers where await j.canJump(to: locator) {
            do { try await j.jump(to: locator); return }
            catch { continue }
        }
    }

    /// Internal — exposed for testing.
    public func _pickPaneTarget(from listOutput: String, tty: String) -> String? {
        for line in listOutput.split(separator: "\n", omittingEmptySubsequences: true) {
            let parts = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2 else { continue }
            if parts[0] == tty[...] { return String(parts[1]) }
        }
        return nil
    }

    // MARK: - Runtime helpers

    private func pickPaneTarget(for tty: String) -> String? {
        guard let bin = findTmuxBinary() else { return nil }
        let proc = Process()
        proc.executableURL = bin
        proc.arguments = ["list-panes", "-a", "-F",
            "#{pane_tty} #{session_name}:#{window_index}.#{pane_index}"]
        let out = Pipe(); proc.standardOutput = out; proc.standardError = Pipe()
        guard (try? proc.run()) != nil else { return nil }
        proc.waitUntilExit()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        let s = String(data: data, encoding: .utf8) ?? ""
        return _pickPaneTarget(from: s, tty: tty)
    }

    private func runTmux(args: [String]) throws {
        guard let bin = findTmuxBinary() else { return }
        let proc = Process()
        proc.executableURL = bin
        proc.arguments = args
        proc.standardOutput = Pipe(); proc.standardError = Pipe()
        try proc.run()
        proc.waitUntilExit()
    }

    private func findTmuxBinary() -> URL? {
        let candidates = [
            "/opt/homebrew/bin/tmux",
            "/usr/local/bin/tmux",
            "/usr/bin/tmux",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
