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
        return measure(screen: screen)
    }

    /// Measure live notch geometry. Try `auxiliaryTopLeftArea`/`auxiliaryTopRightArea`
    /// first; if absent or off, fall back to per-screen-width heuristic.
    /// 14" MBP (~1512pt wide) → ~180pt notch; 16" (~1728pt) → ~200pt.
    @MainActor
    public static func measure(screen: NSScreen) -> NotchInfo {
        let safeTop = screen.safeAreaInsets.top
        guard safeTop > 0 else {
            return NotchInfo(hasNotch: false, notchWidth: 0, notchHeight: 0)
        }
        // Hardware notch widths (measured from MBP camera carve, in points):
        //   14" MBP (1512pt wide): notch ≈ 165pt
        //   16" MBP (1728pt wide): notch ≈ 185pt
        // Aux-region gap can overshoot the hardware carve, so cap it.
        let hardwareNotch: CGFloat = screen.frame.width >= 1700 ? 185 : 165
        if let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let gap = right.minX - left.maxX
            if gap > 0 {
                return NotchInfo(hasNotch: true,
                                 notchWidth: min(gap, hardwareNotch),
                                 notchHeight: safeTop)
            }
        }
        return NotchInfo(hasNotch: true, notchWidth: hardwareNotch, notchHeight: safeTop)
    }

    /// Pure — safe to unit-test without a live screen.
    public static func info(safeAreaTop: CGFloat) -> NotchInfo {
        if safeAreaTop > 0 {
            // Heuristic fallback when live measurement unavailable.
            return NotchInfo(hasNotch: true, notchWidth: 200, notchHeight: safeAreaTop)
        }
        return NotchInfo(hasNotch: false, notchWidth: 0, notchHeight: 0)
    }
}
