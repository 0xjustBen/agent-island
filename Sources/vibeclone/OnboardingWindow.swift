import AppKit
import SwiftUI
import VibeCloneCore

@MainActor
final class OnboardingWindow {
    private var window: NSWindow?
    private weak var controller: MenuBarController?
    private let firstRunFlag: URL

    init(controller: MenuBarController, paths: Paths) {
        self.controller = controller
        self.firstRunFlag = paths.dotDir.appendingPathComponent(".onboarded")
    }

    var hasShownBefore: Bool {
        FileManager.default.fileExists(atPath: firstRunFlag.path)
    }

    func showIfFirstRun() {
        if hasShownBefore { return }
        show()
        try? Data().write(to: firstRunFlag)
    }

    func show() {
        if window == nil { build() }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func build() {
        guard let controller else { return }
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false
        )
        w.title = "Welcome to VibeClone"
        w.center()
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: OnboardingView(controller: controller) {
            w.close()
        })
        self.window = w
    }
}

struct OnboardingView: View {
    @Bindable var controller: MenuBarController
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                PixelLogoView(source: "claude",
                              accent: Color(hex: "#d97757"),
                              pixelSize: 4)
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("VibeClone").font(.system(size: 22, weight: .bold))
                    Text(NSLocalizedString("about.tagline", comment: ""))
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            row(icon: "checkmark.circle.fill", color: .green,
                title: "Hooks installed",
                detail: "Claude Code hooks added to ~/.claude/settings.json (auto-heal enabled).")
            row(icon: "antenna.radiowaves.left.and.right", color: .cyan,
                title: "Listening on UNIX socket",
                detail: "/tmp/vibeclone.sock — local only, mode 0600. Nothing leaves your Mac.")
            row(icon: "bell", color: .orange,
                title: "Look up at your notch",
                detail: "Pill drops out of the notch on active sessions. Click to expand, scroll to retract.")
            row(icon: "keyboard", color: .purple,
                title: "Global hotkey ⌃⇧V",
                detail: "Toggle the panel from anywhere.")
            row(icon: "hand.raised.fill", color: .yellow,
                title: "Two permissions you'll be asked for",
                detail: "Accessibility (focus terminal window) and Automation > System Events (type the chosen option). VibeClone will prompt the first time you click an option in the notch.")
            row(icon: "lock.shield.fill", color: .green,
                title: NSLocalizedString("about.privacy", comment: ""),
                detail: "")
            Spacer()
            HStack {
                Spacer()
                Button("Get started") { onClose() }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 520, height: 420)
    }

    private func row(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold))
                if !detail.isEmpty {
                    Text(detail).font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}
