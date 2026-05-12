import Foundation

public enum DisplayMode: String, Codable, CaseIterable, Sendable {
    case notch
    case floatingBar
    case menuBarOnly
}

public enum NotchExpandStyle: String, Codable, CaseIterable, Sendable {
    case auto      // expand when pending > 0, collapse on click outside
    case pinned    // stay expanded
}
