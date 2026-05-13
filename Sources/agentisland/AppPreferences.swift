import Foundation
import AgentIslandCore

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

    /// When true, pin the pill to a specific screen (`lockedScreenID`) instead
    /// of following the mouse-active screen.
    public var lockToScreen: Bool
    /// `localizedName` of the locked screen, used to find it again across
    /// reboots / hot-plug. Empty when not locked.
    public var lockedScreenName: String

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
                autoApproveTools: [String] = [],
                lockToScreen: Bool = false,
                lockedScreenName: String = "") {
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
        self.lockToScreen = lockToScreen
        self.lockedScreenName = lockedScreenName
    }

    /// True if a request with given tool name should be auto-approved.
    public func shouldAutoApprove(toolName: String) -> Bool {
        autoApproveAll || autoApproveTools.contains(toolName)
    }

    private enum CodingKeys: String, CodingKey {
        case autoHealHooks, soundsEnabled, requestTimeoutSeconds, dedupWindowSeconds,
             noTelemetry, displayMode, notchExpandStyle, soundPack, hotkeyEnabled,
             autoApproveAll, autoApproveTools,
             lockToScreen, lockedScreenName
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppPreferences()
        self.autoHealHooks         = (try? c.decode(Bool.self,    forKey: .autoHealHooks))         ?? d.autoHealHooks
        self.soundsEnabled         = (try? c.decode(Bool.self,    forKey: .soundsEnabled))         ?? d.soundsEnabled
        self.requestTimeoutSeconds = (try? c.decode(Int.self,     forKey: .requestTimeoutSeconds)) ?? d.requestTimeoutSeconds
        self.dedupWindowSeconds    = (try? c.decode(Int.self,     forKey: .dedupWindowSeconds))    ?? d.dedupWindowSeconds
        self.noTelemetry           = (try? c.decode(Bool.self,    forKey: .noTelemetry))           ?? d.noTelemetry
        self.displayMode           = (try? c.decode(DisplayMode.self, forKey: .displayMode))       ?? d.displayMode
        self.notchExpandStyle      = (try? c.decode(NotchExpandStyle.self, forKey: .notchExpandStyle)) ?? d.notchExpandStyle
        self.soundPack             = (try? c.decode(String.self,  forKey: .soundPack))             ?? d.soundPack
        self.hotkeyEnabled         = (try? c.decode(Bool.self,    forKey: .hotkeyEnabled))         ?? d.hotkeyEnabled
        self.autoApproveAll        = (try? c.decode(Bool.self,    forKey: .autoApproveAll))        ?? d.autoApproveAll
        self.autoApproveTools      = (try? c.decode([String].self, forKey: .autoApproveTools))     ?? d.autoApproveTools
        self.lockToScreen          = (try? c.decode(Bool.self,    forKey: .lockToScreen))          ?? d.lockToScreen
        self.lockedScreenName      = (try? c.decode(String.self,  forKey: .lockedScreenName))      ?? d.lockedScreenName
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
