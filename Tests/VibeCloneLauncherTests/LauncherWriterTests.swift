import Testing
import Foundation
@testable import VibeCloneLauncher
@testable import VibeCloneCore

@Test func writes_executable_launcher_with_mdfind_and_orphan_logic() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    let paths = Paths(home: tmp)
    try paths.ensureAll()
    try LauncherWriter.write(paths: paths)
    let s = try String(contentsOf: paths.launcher)
    #expect(s.hasPrefix("#!/bin/zsh"))
    #expect(s.contains("/Contents/Helpers/vibeclone-bridge"))
    #expect(s.contains("/Applications/VibeClone.app"))
    #expect(s.contains(#"kMDItemCFBundleIdentifier == "app.vibeclone.macos""#))
    #expect(s.contains("~/.vibeclone/.orphaned"))
    #expect(s.contains("300"))          // 5-minute grace
    #expect(s.contains("vibeclone-bridge"))
    #expect(s.contains("exit 0"))
    let attrs = try FileManager.default.attributesOfItem(atPath: paths.launcher.path)
    let perms = (attrs[.posixPermissions] as? NSNumber)?.uint16Value ?? 0
    #expect(perms & 0o100 != 0)          // owner executable bit
}

@Test func launcher_exits_zero_when_app_missing_and_no_orphan_flag_yet() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    let paths = Paths(home: tmp)
    try paths.ensureAll()
    try LauncherWriter.write(paths: paths)
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
    proc.arguments = [paths.launcher.path, "--source", "claude"]
    proc.environment = ["HOME": tmp.path, "PATH": "/usr/bin:/bin"]
    // Connect stdin so the shell doesn't hang reading from a TTY.
    let nullIn = Pipe(); proc.standardInput = nullIn
    nullIn.fileHandleForWriting.closeFile()
    try proc.run(); proc.waitUntilExit()
    #expect(proc.terminationStatus == 0)
    #expect(FileManager.default.fileExists(atPath: paths.orphanedFlag.path))
}

@Test func launcher_template_contains_jxa_block() {
    let s = LauncherWriter.template(home: "/Users/test")
    #expect(s.contains("osascript -l JavaScript"))
    #expect(s.contains("vibeclone-bridge"))    // substring matcher in JXA cleanup
    #expect(s.contains(".claude/settings.json"))
}
