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
        // Leave autoresizing on (default true) so contentView fills the panel.
        self.contentView = host
        // Force a layout pass so fittingSize reflects intrinsic content,
        // then size the panel to it. Fall back to a sane default if zero.
        host.layoutSubtreeIfNeeded()
        let fitting = host.fittingSize
        let target = NSSize(
            width:  fitting.width  > 1 ? fitting.width  : 220,
            height: fitting.height > 1 ? fitting.height : 44
        )
        self.setContentSize(target)
    }
}
