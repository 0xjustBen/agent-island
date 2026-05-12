import Foundation
import AppKit

public struct NotchInfo: Equatable, Sendable {
    public let hasNotch: Bool
    public let notchWidth: CGFloat
    public let notchHeight: CGFloat
    public init(hasNotch: Bool, notchWidth: CGFloat, notchHeight: CGFloat) {
        self.hasNotch = hasNotch
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
    }
}

public enum NotchDetector {
    /// Convenience: detect from main screen at call time. Returns `.noNotch` when no screen.
    @MainActor
    public static func detect(screen: NSScreen? = NSScreen.main) -> NotchInfo {
        guard let screen else { return NotchInfo(hasNotch: false, notchWidth: 0, notchHeight: 0) }
        return info(safeAreaTop: screen.safeAreaInsets.top)
    }

    /// Pure — safe to unit-test without a live screen.
    public static func info(safeAreaTop: CGFloat) -> NotchInfo {
        if safeAreaTop > 0 {
            // Heuristic: notch width on 14"/16" MacBook Pro is ~180pt.
            return NotchInfo(hasNotch: true, notchWidth: 180, notchHeight: safeAreaTop)
        }
        return NotchInfo(hasNotch: false, notchWidth: 0, notchHeight: 0)
    }
}
