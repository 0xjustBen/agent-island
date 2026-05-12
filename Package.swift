// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "VibeClone",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "VibeCloneCore", targets: ["VibeCloneCore"]),
        .library(name: "VibeCloneAdapters", targets: ["VibeCloneAdapters"]),
        .library(name: "VibeCloneLauncher", targets: ["VibeCloneLauncher"]),
        .library(name: "VibeCloneTerminals", targets: ["VibeCloneTerminals"]),
        .executable(name: "vibeclone", targets: ["vibeclone"]),
        .executable(name: "vibeclone-bridge", targets: ["vibeclone-bridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    ],
    targets: [
        .target(name: "VibeCloneCore", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOPosix", package: "swift-nio"),
        ]),
        .target(name: "VibeCloneAdapters", dependencies: ["VibeCloneCore"]),
        .target(name: "VibeCloneLauncher", dependencies: ["VibeCloneCore"]),
        .target(name: "VibeCloneTerminals", dependencies: ["VibeCloneCore"]),
        .executableTarget(name: "vibeclone", dependencies: [
            "VibeCloneCore", "VibeCloneAdapters", "VibeCloneLauncher", "VibeCloneTerminals",
        ]),
        .executableTarget(name: "vibeclone-bridge", dependencies: [
            "VibeCloneCore", "VibeCloneAdapters",
        ]),
        .testTarget(name: "VibeCloneCoreTests", dependencies: ["VibeCloneCore"]),
        .testTarget(name: "VibeCloneAdaptersTests", dependencies: ["VibeCloneAdapters"],
                    resources: [
                        .copy("Fixtures/settings-empty.json"),
                        .copy("Fixtures/settings-with-comments.jsonc"),
                        .copy("Fixtures/settings-with-existing-hooks.json"),
                        .copy("Fixtures/cc-bash.json"),
                        .copy("Fixtures/cc-edit.json"),
                        .copy("Fixtures/cc-permissionrequest.json"),
                        .copy("Fixtures/cc-sessionstart.json"),
                    ]),
        .testTarget(name: "VibeCloneLauncherTests", dependencies: ["VibeCloneLauncher"]),
        .testTarget(name: "VibeCloneTerminalsTests", dependencies: ["VibeCloneTerminals"]),
    ]
)
