import Foundation
import VibeCloneCore

public struct AppPreferences: Codable, Sendable {
    public var autoHealHooks: Bool
    public var soundsEnabled: Bool
    public var requestTimeoutSeconds: Int
    public var dedupWindowSeconds: Int
    /// Marker: always true for this clone — zero telemetry differentiator from Vibe Island.
    public var noTelemetry: Bool

    public init(autoHealHooks: Bool = true,
                soundsEnabled: Bool = true,
                requestTimeoutSeconds: Int = 86_400,
                dedupWindowSeconds: Int = 5,
                noTelemetry: Bool = true) {
        self.autoHealHooks = autoHealHooks
        self.soundsEnabled = soundsEnabled
        self.requestTimeoutSeconds = requestTimeoutSeconds
        self.dedupWindowSeconds = dedupWindowSeconds
        self.noTelemetry = noTelemetry
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
