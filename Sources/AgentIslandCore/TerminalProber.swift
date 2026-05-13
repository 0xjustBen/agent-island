import Foundation
#if canImport(Darwin)
import Darwin
#endif

public enum ProbedTerminal: String, Codable, Sendable, Hashable {
    case iTerm2, terminalApp, ghostty, warp, vscode, cursor, alacritty, kitty, tmux, unknown
}

/// Walks the process tree starting from `startPid`, matches each `comm` string
/// against known terminal process names, and returns the first match (or
/// `.unknown` if none found before reaching pid 1).
///
/// The walk depth is capped at 16 to avoid infinite loops on malformed lineage
/// data.
public enum TerminalProber {

    public typealias LineageProvider = (pid_t) -> (ppid: pid_t, comm: String)?

    public static func probe(startPid: pid_t, lineage: LineageProvider) -> ProbedTerminal {
        var pid = startPid
        var seen = Set<pid_t>()
        for _ in 0..<16 {
            guard !seen.contains(pid) else { return .unknown }
            seen.insert(pid)
            guard let entry = lineage(pid) else { return .unknown }
            if let match = match(comm: entry.comm) {
                return match
            }
            if entry.ppid <= 1 { return .unknown }
            pid = entry.ppid
        }
        return .unknown
    }

    /// Live macOS process tree lookup using libproc. Suitable for production
    /// use; tests should inject their own closure.
    public static func liveLineageProvider() -> LineageProvider {
        return { pid in
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/ps")
            proc.arguments = ["-p", String(pid), "-o", "ppid=,comm="]
            let out = Pipe(); proc.standardOutput = out
            proc.standardError = Pipe()
            do {
                try proc.run(); proc.waitUntilExit()
                let data = out.fileHandleForReading.readDataToEndOfFile()
                let s = String(data: data, encoding: .utf8) ?? ""
                let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                guard parts.count == 2, let ppid = pid_t(parts[0]) else { return nil }
                let comm = String(parts[1])
                let basename = (comm as NSString).lastPathComponent
                return (ppid, basename)
            } catch { return nil }
        }
    }

    /// Convenience: probe using the live macOS process tree.
    public static func probeLive(startPid: pid_t) -> ProbedTerminal {
        return probe(startPid: startPid, lineage: liveLineageProvider())
    }

    private static func match(comm: String) -> ProbedTerminal? {
        let c = comm.lowercased()
        if c == "tmux" || c.hasPrefix("tmux:")  { return .tmux }
        if c == "iterm2" || c == "iterm" || c.hasPrefix("iterm.")  { return .iTerm2 }
        if c == "terminal"                       { return .terminalApp }
        if c.contains("ghostty")                 { return .ghostty }
        if c == "warp" || c == "stable"          { return .warp }
        if c.contains("code helper") || c == "code" || c == "code-helper" { return .vscode }
        if c.contains("cursor")                  { return .cursor }
        if c == "alacritty"                      { return .alacritty }
        if c == "kitty"                          { return .kitty }
        return nil
    }
}
