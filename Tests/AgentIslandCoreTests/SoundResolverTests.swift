import Testing
import Foundation
@testable import AgentIslandCore

@Test func resolve_returns_nil_when_neither_exists() {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    let paths = Paths(home: tmp)
    let result = SoundResolver.resolve(name: "permission", paths: paths, bundleURL: nil)
    #expect(result == nil)
}

@Test func resolve_returns_bundled_when_only_bundled_exists() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    let paths = Paths(home: tmp)
    let bundleDir = FileManager.default.temporaryDirectory.appendingPathComponent("bundle-\(UUID())")
    try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
    let bundled = bundleDir.appendingPathComponent("permission.aiff")
    try Data("bundled".utf8).write(to: bundled)
    let result = SoundResolver.resolve(name: "permission", paths: paths, bundleURL: bundleDir)
    #expect(result?.path == bundled.path)
}

@Test func resolve_returns_custom_over_bundled() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("home-\(UUID())")
    let paths = Paths(home: tmp)
    try paths.ensureAll()
    let customDir = paths.dotDir.appendingPathComponent("custom-sounds")
    try FileManager.default.createDirectory(at: customDir, withIntermediateDirectories: true)
    let custom = customDir.appendingPathComponent("permission.aiff")
    try Data("custom".utf8).write(to: custom)
    let bundleDir = FileManager.default.temporaryDirectory.appendingPathComponent("bundle-\(UUID())")
    try FileManager.default.createDirectory(at: bundleDir, withIntermediateDirectories: true)
    let bundled = bundleDir.appendingPathComponent("permission.aiff")
    try Data("bundled".utf8).write(to: bundled)
    let result = SoundResolver.resolve(name: "permission", paths: paths, bundleURL: bundleDir)
    #expect(result?.path == custom.path)
}
