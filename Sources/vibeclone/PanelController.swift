import AppKit
import SwiftUI
import VibeCloneCore

@MainActor
final class PanelController {
    private var panel: FloatingPanel?
    private unowned let controller: MenuBarController
    private var currentMode: DisplayMode = .menuBarOnly

    init(controller: MenuBarController) {
        self.controller = controller
    }

    /// Find the screen that has the camera notch (safeAreaInsets.top > 0).
    /// Falls back to the main screen if none has a notch.
    private func notchScreen() -> NSScreen {
        if let notched = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            return notched
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }

    func updateForMode(_ mode: DisplayMode) {
        currentMode = mode
        switch mode {
        case .menuBarOnly:
            hide()
        case .notch:
            let screen = notchScreen()
            show(style: .notch(NotchDetector.info(safeAreaTop: screen.safeAreaInsets.top)),
                 screen: screen)
        case .floatingBar:
            show(style: .bar, screen: NSScreen.main ?? NSScreen.screens.first!)
        }
    }

    /// Re-position + redraw with current state. Called when pendingCount changes.
    func refresh() {
        guard currentMode != .menuBarOnly else { return }
        if currentMode == .notch {
            let screen = notchScreen()
            show(style: .notch(NotchDetector.info(safeAreaTop: screen.safeAreaInsets.top)),
                 screen: screen)
        } else {
            show(style: .bar, screen: NSScreen.main ?? NSScreen.screens.first!)
        }
    }

    private func show(style: NotchStyle, screen: NSScreen) {
        if panel == nil {
            panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 60))
        }
        let view = NotchView(controller: controller, style: style)
        panel?.setContent(view)
        position(on: screen)
        panel?.orderFrontRegardless()
    }

    private func hide() {
        panel?.orderOut(nil)
    }

    private func position(on screen: NSScreen) {
        guard let p = panel else { return }
        let screenFrame = screen.frame
        let panelFrame = p.frame
        let centerX = screenFrame.midX - panelFrame.width / 2
        // Anchor panel TOP to screen TOP so the panel rectangle covers the
        // notch zone. NotchView pads its content down by notchHeight (or
        // menuBarHeight for .bar) so visible UI sits just below the notch.
        let originY = screenFrame.maxY - panelFrame.height
        p.setFrameOrigin(NSPoint(x: centerX, y: originY))
    }
}
