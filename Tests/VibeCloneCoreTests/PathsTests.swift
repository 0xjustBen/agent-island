import Testing
import Foundation
@testable import VibeCloneCore

@Test func paths_match_vibe_island_namespace_renamed() {
    let p = Paths(home: URL(fileURLWithPath: "/Users/bob"))
    #expect(p.socket.path == "/tmp/vibeclone.sock")
    #expect(p.diagnosticLog.path == "/tmp/vibeclone-diagnostic.log")
    #expect(p.runDir.path == "/Users/bob/.vibeclone/run")
    #expect(p.binDir.path == "/Users/bob/.vibeclone/bin")
    #expect(p.launcher.path == "/Users/bob/.vibeclone/bin/vibeclone-bridge")
    #expect(p.bridgeCache.path == "/Users/bob/.vibeclone/bin/.bridge-cache")
    #expect(p.orphanedFlag.path == "/Users/bob/.vibeclone/.orphaned")
    #expect(p.lastRun.path == "/Users/bob/.vibeclone/run/vibeclone.lastrun")
    #expect(p.appSupport.path == "/Users/bob/Library/Application Support/vibeclone")
    #expect(p.sessionTerminals.path == "/Users/bob/Library/Application Support/vibeclone/session-terminals.json")
    #expect(p.logDir.path == "/Users/bob/Library/Logs/VibeClone")
    #expect(p.logFile.path == "/Users/bob/Library/Logs/VibeClone/vibeclone.log")
    #expect(p.historyJSONL.path == "/Users/bob/Library/Logs/VibeClone/history.jsonl")
    #expect(p.claudeSettings.path == "/Users/bob/.claude/settings.json")
    #expect(p.claudeSettingsBackup.path == "/Users/bob/.claude/settings.json.vibeclone-backup")
}
