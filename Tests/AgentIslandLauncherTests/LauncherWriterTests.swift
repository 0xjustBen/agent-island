import Testing
import Foundation
@testable import AgentIslandLauncher
@testable import AgentIslandCore

@Test func writes_executable_launcher_with_mdfind_and_orphan_logic() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    let paths = Paths(home: tmp)
    try paths.ensureAll()
    try LauncherWriter.write(paths: paths)
    let s = try String(contentsOf: paths.launcher)
    #expect(s.hasPrefix("#!/bin/zsh"))
    #expect(s.contains("/Contents/Helpers/agentisland-bridge"))
    #expect(s.contains("/Applications/AgentIsland.app"))
    #expect(s.contains(#"kMDItemCFBundleIdentifier == "app.agentisland.macos""#))
    #expect(s.contains("~/.agentisland/.orphaned"))
    #expect(s.contains("300"))          // 5-minute grace
    #expect(s.contains("agentisland-bridge"))
    #expect(s.contains("exit 0"))
    let attrs = try FileManager.default.attributesOfItem(atPath: paths.launcher.path)
    let perms = (attrs[.posixPermissions] as? NSNumber)?.uint16Value ?? 0
    #expect(perms & 0o100 != 0)          // owner executable bit
}

@Test func launcher_always_exits_zero() throws {
    // Either path is correct: app located via mdfind (execs bridge) OR not found
    // (marks orphan). Both produce exit 0. The launcher must never block CC.
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    let paths = Paths(home: tmp)
    try paths.ensureAll()
    try LauncherWriter.write(paths: paths)
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
    proc.arguments = [paths.launcher.path, "--source", "claude"]
    proc.environment = ["HOME": tmp.path, "PATH": "/usr/bin:/bin"]
    let nullIn = Pipe(); proc.standardInput = nullIn
    nullIn.fileHandleForWriting.closeFile()
    let nullOut = Pipe(); proc.standardOutput = nullOut
    let nullErr = Pipe(); proc.standardError = nullErr
    try proc.run(); proc.waitUntilExit()
    #expect(proc.terminationStatus == 0)
}

@Test func launcher_template_contains_jxa_block() {
    let s = LauncherWriter.template(home: "/Users/test")
    #expect(s.contains("osascript -l JavaScript"))
    #expect(s.contains("agentisland-bridge"))    // substring matcher in JXA cleanup
    #expect(s.contains(".claude/settings.json"))
}
