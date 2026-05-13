import Foundation

public struct Paths: Sendable {
    public let home: URL
    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser) { self.home = home }

    public var socket: URL          { URL(fileURLWithPath: "/tmp/agentisland.sock") }
    public var diagnosticLog: URL   { URL(fileURLWithPath: "/tmp/agentisland-diagnostic.log") }

    public var dotDir: URL          { home.appendingPathComponent(".agentisland", isDirectory: true) }
    public var binDir: URL          { dotDir.appendingPathComponent("bin", isDirectory: true) }
    public var runDir: URL          { dotDir.appendingPathComponent("run", isDirectory: true) }
    public var launcher: URL        { binDir.appendingPathComponent("agentisland-bridge") }
    public var bridgeCache: URL     { binDir.appendingPathComponent(".bridge-cache") }
    public var orphanedFlag: URL    { dotDir.appendingPathComponent(".orphaned") }
    public var lastRun: URL         { runDir.appendingPathComponent("agentisland.lastrun") }
    public var config: URL          { dotDir.appendingPathComponent("config.json") }

    public var appSupport: URL      { home.appendingPathComponent("Library/Application Support/agentisland", isDirectory: true) }
    public var sessionTerminals: URL { appSupport.appendingPathComponent("session-terminals.json") }

    public var logDir: URL          { home.appendingPathComponent("Library/Logs/AgentIsland", isDirectory: true) }
    public var logFile: URL         { logDir.appendingPathComponent("agentisland.log") }
    public var historyJSONL: URL    { logDir.appendingPathComponent("history.jsonl") }

    public var claudeDir: URL       { home.appendingPathComponent(".claude", isDirectory: true) }
    public var claudeSettings: URL  { claudeDir.appendingPathComponent("settings.json") }
    public var claudeSettingsBackup: URL { claudeDir.appendingPathComponent("settings.json.agentisland-backup") }

    public func ensureAll() throws {
        let fm = FileManager.default
        for d in [dotDir, binDir, runDir, appSupport, logDir] {
            try fm.createDirectory(at: d, withIntermediateDirectories: true)
        }
    }
}
