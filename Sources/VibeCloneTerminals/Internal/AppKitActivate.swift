import Foundation
import AppKit

enum AppKitActivate {
    static func isRunning(bundleId: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleId
        }
    }

    static func activate(bundleId: String) async throws {
        if let app = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == bundleId
        }) {
            app.activate(options: [])
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            let cfg = NSWorkspace.OpenConfiguration()
            cfg.activates = true
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: cfg)
        }
    }

    /// Run an AppleScript source string. Swallows AppleScript errors except
    /// for Automation-permission denial which we surface explicitly.
    static func runAppleScript(_ source: String) throws {
        var err: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return }
        _ = script.executeAndReturnError(&err)
        if let e = err,
           let code = e[NSAppleScript.errorNumber] as? Int,
           code == -1743 {
            throw NSError(domain: "VibeCloneTerminals", code: -1743,
                          userInfo: [NSLocalizedDescriptionKey: "Automation permission denied"])
        }
    }
}
