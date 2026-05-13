import Foundation
import AppKit
import VibeCloneCore

/// Uses kitty's remote-control protocol (`kitty @ focus-window --match tty:<tty>`).
/// Requires `allow_remote_control yes` in user's kitty.conf.
public struct KittyJumper: TerminalJumper {
    public let id = "kitty"
    public let probedKind: ProbedTerminal = .kitty
    public init() {}

    public func canJump(to: TerminalLocator) async -> Bool {
        AppKitActivate.isRunning(bundleId: "net.kovidgoyal.kitty")
    }

    public func jump(to locator: TerminalLocator) async throws {
        guard await canJump(to: locator) else {
            throw TerminalJumpError.appNotRunning("kitty")
        }
        if let tty = locator.tty {
            _ = try? runKitty(args: ["@", "focus-window", "--match", "tty:\(tty)"])
        }
        try await AppKitActivate.activate(bundleId: "net.kovidgoyal.kitty")
    }

    /// Internal — exposed for testing.
    public func _command(for locator: TerminalLocator) -> [String]? {
        guard let tty = locator.tty else { return nil }
        return ["@", "focus-window", "--match", "tty:\(tty)"]
    }

    private func runKitty(args: [String]) throws {
        guard let bin = findKittyBinary() else { return }
        let proc = Process()
        proc.executableURL = bin
        proc.arguments = args
        let out = Pipe(); proc.standardOutput = out; proc.standardError = Pipe()
        try proc.run()
        proc.waitUntilExit()
    }

    private func findKittyBinary() -> URL? {
        let candidates = [
            "/Applications/kitty.app/Contents/MacOS/kitty",
            "/opt/homebrew/bin/kitty",
            "/usr/local/bin/kitty",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
