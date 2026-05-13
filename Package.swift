// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AgentIsland",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AgentIslandCore", targets: ["AgentIslandCore"]),
        .library(name: "AgentIslandAdapters", targets: ["AgentIslandAdapters"]),
        .library(name: "AgentIslandLauncher", targets: ["AgentIslandLauncher"]),
        .library(name: "AgentIslandTerminals", targets: ["AgentIslandTerminals"]),
        .executable(name: "agentisland", targets: ["agentisland"]),
        .executable(name: "agentisland-bridge", targets: ["agentisland-bridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    ],
    targets: [
        .target(name: "AgentIslandCore", dependencies: [
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOPosix", package: "swift-nio"),
        ]),
        .target(name: "AgentIslandAdapters", dependencies: ["AgentIslandCore"]),
        .target(name: "AgentIslandLauncher", dependencies: ["AgentIslandCore"]),
        .target(name: "AgentIslandTerminals", dependencies: ["AgentIslandCore"]),
        .executableTarget(name: "agentisland", dependencies: [
            "AgentIslandCore", "AgentIslandAdapters", "AgentIslandLauncher", "AgentIslandTerminals",
        ]),
        .executableTarget(name: "agentisland-bridge", dependencies: [
            "AgentIslandCore", "AgentIslandAdapters",
        ]),
        .testTarget(name: "AgentIslandCoreTests", dependencies: ["AgentIslandCore"]),
        .testTarget(name: "AgentIslandAdaptersTests", dependencies: ["AgentIslandAdapters"],
                    resources: [
                        .copy("Fixtures/settings-empty.json"),
                        .copy("Fixtures/settings-with-comments.jsonc"),
                        .copy("Fixtures/settings-with-existing-hooks.json"),
                        .copy("Fixtures/cc-bash.json"),
                        .copy("Fixtures/cc-edit.json"),
                        .copy("Fixtures/cc-permissionrequest.json"),
                        .copy("Fixtures/cc-sessionstart.json"),
                    ]),
        .testTarget(name: "AgentIslandLauncherTests", dependencies: ["AgentIslandLauncher"]),
        .testTarget(name: "AgentIslandTerminalsTests", dependencies: ["AgentIslandTerminals"]),
    ]
)
