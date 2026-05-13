import AppKit
import SwiftUI

/// Borderless, non-activating, above-menu-bar floating panel. Same window used
/// for both the notch widget and the floating-bar fallback — positioning differs.
final class FloatingPanel: NSPanel {
    var onScroll: (() -> Void)?
    var onMouseEntered: (() -> Void)?
    var onMouseExited: (() -> Void)?

    override func scrollWheel(with event: NSEvent) {
        // Scrolling over the panel triggers expand (handled by caller).
        if abs(event.scrollingDeltaY) > 1 || abs(event.scrollingDeltaX) > 1 {
            onScroll?()
        }
        super.scrollWheel(with: event)
    }

    private var trackingArea: NSTrackingArea?
    func installHoverTracking() {
        guard let view = contentView else { return }
        if let ta = trackingArea { view.removeTrackingArea(ta) }
        let ta = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        view.addTrackingArea(ta)
        trackingArea = ta
    }

    override func mouseEntered(with event: NSEvent) { onMouseEntered?() }
    override func mouseExited(with event: NSEvent)  { onMouseExited?()  }

    init(contentRect: NSRect) {
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        self.isMovable = true
        self.isMovableByWindowBackground = true
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

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Borderless non-activating panels swallow the first click unless they
    /// become key. SwiftUI buttons rely on key-window status to fire.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown && !isKeyWindow { makeKey() }
        super.sendEvent(event)
    }


    /// Replace the panel content with a SwiftUI view.
    /// Panel WIDTH stays fixed (caller sets it via initial contentRect).
    /// Only HEIGHT adapts to the content's fitting size — keeps the panel
    /// rectangle wide enough that SwiftUI centers its inner pill/card.
    func setContent<V: View>(_ view: V) {
        let host = NSHostingView(rootView: view.ignoresSafeArea(.all))
        if #available(macOS 13.3, *) {
            host.sceneBridgingOptions = []
        }
        self.contentView = host
        host.layoutSubtreeIfNeeded()
        let fitting = host.fittingSize
        let target = NSSize(
            width:  fitting.width  > 1 ? fitting.width  : 300,
            height: fitting.height > 1 ? fitting.height : 60
        )
        self.setContentSize(target)
    }
}
