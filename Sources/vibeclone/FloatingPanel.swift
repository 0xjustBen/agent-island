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
    func setContent<V: View>(_ view: V) {
        let host = NSHostingView(rootView: view)
        host.translatesAutoresizingMaskIntoConstraints = false
        self.contentView = host
        // Size panel to the SwiftUI view's intrinsic size.
        let fitting = host.fittingSize
        if fitting.width > 0 && fitting.height > 0 {
            self.setContentSize(fitting)
        }
    }
}
