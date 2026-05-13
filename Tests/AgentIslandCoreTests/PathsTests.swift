import Testing
import Foundation
@testable import AgentIslandCore

@Test func paths_match_vibe_island_namespace_renamed() {
    let p = Paths(home: URL(fileURLWithPath: "/Users/bob"))
    #expect(p.socket.path == "/tmp/agentisland.sock")
    #expect(p.diagnosticLog.path == "/tmp/agentisland-diagnostic.log")
    #expect(p.runDir.path == "/Users/bob/.agentisland/run")
    #expect(p.binDir.path == "/Users/bob/.agentisland/bin")
    #expect(p.launcher.path == "/Users/bob/.agentisland/bin/agentisland-bridge")
    #expect(p.bridgeCache.path == "/Users/bob/.agentisland/bin/.bridge-cache")
    #expect(p.orphanedFlag.path == "/Users/bob/.agentisland/.orphaned")
    #expect(p.lastRun.path == "/Users/bob/.agentisland/run/agentisland.lastrun")
    #expect(p.appSupport.path == "/Users/bob/Library/Application Support/agentisland")
    #expect(p.sessionTerminals.path == "/Users/bob/Library/Application Support/agentisland/session-terminals.json")
    #expect(p.logDir.path == "/Users/bob/Library/Logs/AgentIsland")
    #expect(p.logFile.path == "/Users/bob/Library/Logs/AgentIsland/agentisland.log")
    #expect(p.historyJSONL.path == "/Users/bob/Library/Logs/AgentIsland/history.jsonl")
    #expect(p.claudeSettings.path == "/Users/bob/.claude/settings.json")
    #expect(p.claudeSettingsBackup.path == "/Users/bob/.claude/settings.json.agentisland-backup")
}
