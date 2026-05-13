import AppKit
import SwiftUI

/// Borderless, non-activating, above-menu-bar floating panel. Same window used
/// for both the notch widget and the floating-bar fallback — positioning differs.
final class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        self.isMovable = false
        self.isFloatingPanel = true
        self.level = .statusBar
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.hasShadow = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Replace the panel content with a SwiftUI view.
    /// Panel WIDTH stays fixed (caller sets it via initial contentRect).
    /// Only HEIGHT adapts to the content's fitting size — keeps the panel
    /// rectangle wide enough that SwiftUI centers its inner pill/card.
    func setContent<V: View>(_ view: V) {
        let host = NSHostingView(rootView: view)
        self.contentView = host
        host.layoutSubtreeIfNeeded()
        let fitting = host.fittingSize
        let target = NSSize(
            width:  self.frame.width,                       // preserve width
            height: fitting.height > 1 ? fitting.height : 60
        )
        self.setContentSize(target)
    }
}
