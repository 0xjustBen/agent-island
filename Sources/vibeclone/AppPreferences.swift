import Foundation
import VibeCloneCore

public struct AppPreferences: Codable, Sendable {
    public var autoHealHooks: Bool
    public var soundsEnabled: Bool
    public var requestTimeoutSeconds: Int
    public var dedupWindowSeconds: Int
    /// Marker: always true for this clone — zero telemetry differentiator from Vibe Island.
    public var noTelemetry: Bool

    // Phase 2 additions
    public var displayMode: DisplayMode
    public var notchExpandStyle: NotchExpandStyle
    public var soundPack: String
    public var hotkeyEnabled: Bool

    // Phase 4.5 — auto-approve
    /// Global auto-approve for any permission request. Off by default.
    public var autoApproveAll: Bool
    /// Allowed tool names for auto-approve when `autoApproveAll` is false.
    /// Example: ["Read", "Glob", "Grep"] = safe read-only tools.
    public var autoApproveTools: [String]

    public init(autoHealHooks: Bool = true,
                soundsEnabled: Bool = true,
                requestTimeoutSeconds: Int = 86_400,
                dedupWindowSeconds: Int = 5,
                noTelemetry: Bool = true,
                displayMode: DisplayMode = .notch,
                notchExpandStyle: NotchExpandStyle = .auto,
                soundPack: String = "default",
                hotkeyEnabled: Bool = true,
                autoApproveAll: Bool = false,
                autoApproveTools: [String] = []) {
        self.autoHealHooks = autoHealHooks
        self.soundsEnabled = soundsEnabled
        self.requestTimeoutSeconds = requestTimeoutSeconds
        self.dedupWindowSeconds = dedupWindowSeconds
        self.noTelemetry = noTelemetry
        self.displayMode = displayMode
        self.notchExpandStyle = notchExpandStyle
        self.soundPack = soundPack
        self.hotkeyEnabled = hotkeyEnabled
        self.autoApproveAll = autoApproveAll
        self.autoApproveTools = autoApproveTools
    }

    /// True if a request with given tool name should be auto-approved.
    public func shouldAutoApprove(toolName: String) -> Bool {
        autoApproveAll || autoApproveTools.contains(toolName)
    }

    public static func load(paths: Paths) -> AppPreferences {
        guard let data = try? Data(contentsOf: paths.config),
              let p = try? JSONDecoder().decode(AppPreferences.self, from: data) else {
            return AppPreferences()
        }
        return p
    }

    public func save(paths: Paths) {
        try? paths.ensureAll()
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: paths.config)
        }
    }
}
