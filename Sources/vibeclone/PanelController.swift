import AppKit
import SwiftUI
import VibeCloneCore

@MainActor
final class PanelController {
    private var panel: FloatingPanel?
    private unowned let controller: MenuBarController
    private var currentMode: DisplayMode = .menuBarOnly
    private var pendingRetract: DispatchWorkItem?

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

    /// Pick screen mouse currently sits on; if pref `lockToScreen`, return
    /// the screen with matching localizedName instead.
    private func activeScreen() -> NSScreen {
        let prefs = controller.prefs
        if prefs.lockToScreen, !prefs.lockedScreenName.isEmpty,
           let pinned = NSScreen.screens.first(where: { $0.localizedName == prefs.lockedScreenName }) {
            return pinned
        }
        let mouse = NSEvent.mouseLocation
        if let hit = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
            return hit
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }

    func updateForMode(_ mode: DisplayMode) {
        currentMode = mode
        switch mode {
        case .menuBarOnly:
            hide()
        case .notch:
            let screen = activeScreen()
            let info = NotchDetector.measure(screen: screen)
            let style: NotchStyle = info.hasNotch ? .notch(info) : .bar
            show(style: style, screen: screen)
        case .floatingBar:
            show(style: .bar, screen: activeScreen())
        }
    }

    /// Re-position + redraw with current state. Called when pendingCount changes.
    func refresh() {
        guard currentMode != .menuBarOnly else { return }
        let screen = activeScreen()
        if currentMode == .notch {
            let info = NotchDetector.measure(screen: screen)
            let style: NotchStyle = info.hasNotch ? .notch(info) : .bar
            show(style: style, screen: screen)
        } else {
            show(style: .bar, screen: screen)
        }
    }

    private func show(style: NotchStyle, screen: NSScreen) {
        let desiredWidth: CGFloat = min(460, screen.frame.width - 40)
        let desiredHeight: CGFloat = 480
        if panel == nil {
            panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: desiredWidth, height: desiredHeight))
            panel!.onScroll       = { [weak self] in self?.controller.notchExpanded = true }
            panel!.onMouseEntered = { [weak self] in self?.controller.notchExpanded = true }
            panel!.onMouseExited  = { [weak self] in
                guard let self else { return }
                // Retract after a short delay so a button click on the expanded
                // panel doesn't trigger an immediate exit.
                let task = DispatchWorkItem { [weak self] in
                    self?.controller.notchExpanded = false
                }
                self.pendingRetract?.cancel()
                self.pendingRetract = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: task)
            }
        } else {
            var f = panel!.frame
            f.size = NSSize(width: desiredWidth, height: desiredHeight)
            panel!.setFrame(f, display: false)
        }
        let view = NotchView(controller: controller, style: style)
        panel?.setContent(view)
        panel?.installHoverTracking()
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
        // Panel TOP edge sits just below notch (or menubar). Pill renders at
        // panel top → flush against notch bottom edge.
        // Panel top edge sits at the very top of the screen so the pill
        // renders IN the menubar/notch area. On notched screens the pill is
        // sized wider than the camera carve so its wings extend visibly into
        // the menubar on either side of the notch.
        let originY = screenFrame.maxY - panelFrame.height
        p.setFrameOrigin(NSPoint(x: centerX, y: originY))
    }
}
