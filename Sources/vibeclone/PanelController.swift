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

    func updateForMode(_ mode: DisplayMode) {
        currentMode = mode
        switch mode {
        case .menuBarOnly:
            hide()
        case .notch:
            show(style: .notch(NotchDetector.detect()))
        case .floatingBar:
            show(style: .bar)
        }
    }

    /// Re-position + redraw with current state. Called when pendingCount changes.
    func refresh() {
        guard currentMode != .menuBarOnly else { return }
        let style: NotchStyle = (currentMode == .notch)
            ? .notch(NotchDetector.detect())
            : .bar
        show(style: style)
    }

    private func show(style: NotchStyle) {
        if panel == nil {
            panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 60))
        }
        let view = NotchView(controller: controller, style: style)
        panel?.setContent(view)
        position(style: style)
        panel?.orderFrontRegardless()
    }

    private func hide() {
        panel?.orderOut(nil)
    }

    private func position(style: NotchStyle) {
        guard let screen = NSScreen.main, let p = panel else { return }
        let screenFrame = screen.frame
        let panelFrame = p.frame
        let centerX = screenFrame.midX - panelFrame.width / 2
        let topY: CGFloat = {
            switch style {
            case .notch(let info):
                // Position just below the notch.
                return screenFrame.maxY - info.notchHeight - panelFrame.height - 8
            case .bar:
                // ~28pt menu bar; leave 8pt gap.
                return screenFrame.maxY - 28 - panelFrame.height - 8
            }
        }()
        p.setFrameOrigin(NSPoint(x: centerX, y: topY))
    }
}
