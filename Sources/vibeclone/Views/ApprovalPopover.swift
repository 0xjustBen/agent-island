import SwiftUI
import AppKit
import VibeCloneCore

struct ApprovalPopover: View {
    @Bindable var controller: MenuBarController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Divider()
            ScrollView {
                SessionListView(controller: controller)
            }
            .frame(maxHeight: 460)
            Divider()
            EventTicker(activeSessions: controller.activeSessionsCount,
                        lastEventAt: controller.lastEventAt)
            footer
        }
        .padding(12)
        .frame(width: 480)
    }

    private var header: some View {
        HStack {
            Text("VibeClone").font(.headline)
            Spacer()
            Text("Pending: \(controller.pendingCount)")
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            // Row 1: display mode + global toggles
            HStack {
                Picker("Display", selection: Binding(
                    get: { controller.prefs.displayMode },
                    set: { newValue in
                        controller.prefs.displayMode = newValue
                        controller.panelController?.updateForMode(newValue)
                    }
                )) {
                    Text("Notch").tag(DisplayMode.notch)
                    Text("Bar").tag(DisplayMode.floatingBar)
                    Text("Menu only").tag(DisplayMode.menuBarOnly)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 150)

                Toggle("Auto-heal", isOn: Binding(
                    get: { controller.prefs.autoHealHooks },
                    set: { controller.prefs.autoHealHooks = $0 }
                ))
                .toggleStyle(.switch)
                Toggle("Sounds", isOn: Binding(
                    get: { controller.prefs.soundsEnabled },
                    set: { controller.prefs.soundsEnabled = $0 }
                ))
                .toggleStyle(.switch)
                Spacer()
                Button { controller.openHistoryViewer() } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .buttonStyle(.plain).help("History")
                Button { controller.revealLogsInFinder() } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .buttonStyle(.plain).help("Reveal logs in Finder")
                Button { controller.clearAllSessions() } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain).help("Clear all sessions")
                Button { controller.resetPrefs() } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.plain).help("Reset preferences")
                Button {
                    controller.shutdown()
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
                .help("Quit VibeClone")
            }
            // Row 2: auto-approve controls
            HStack(spacing: 8) {
                Toggle("Auto-approve all", isOn: Binding(
                    get: { controller.prefs.autoApproveAll },
                    set: { controller.prefs.autoApproveAll = $0 }
                ))
                .toggleStyle(.switch)
                .help("Auto-approve every permission request (dangerous)")

                if !controller.prefs.autoApproveAll {
                    ForEach(["Read", "Glob", "Grep", "Bash", "Edit", "Write"], id: \.self) { tool in
                        Toggle(isOn: Binding(
                            get: { controller.prefs.autoApproveTools.contains(tool) },
                            set: { on in
                                var set = Set(controller.prefs.autoApproveTools)
                                if on { set.insert(tool) } else { set.remove(tool) }
                                controller.prefs.autoApproveTools = Array(set).sorted()
                            }
                        )) { Text(tool).font(.caption) }
                        .toggleStyle(.button)
                        .controlSize(.mini)
                    }
                }
                Spacer()
            }
            // Row 3: screen lock
            HStack(spacing: 8) {
                Toggle("Lock to screen", isOn: Binding(
                    get: { controller.prefs.lockToScreen },
                    set: {
                        controller.prefs.lockToScreen = $0
                        if $0, controller.prefs.lockedScreenName.isEmpty,
                           let s = NSScreen.main {
                            controller.prefs.lockedScreenName = s.localizedName
                        }
                        controller.panelController?.refresh()
                    }
                ))
                .toggleStyle(.switch)
                if controller.prefs.lockToScreen {
                    Picker("", selection: Binding(
                        get: { controller.prefs.lockedScreenName },
                        set: {
                            controller.prefs.lockedScreenName = $0
                            controller.panelController?.refresh()
                        }
                    )) {
                        ForEach(NSScreen.screens, id: \.localizedName) { screen in
                            Text(screen.localizedName).tag(screen.localizedName)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 180)
                }
                Spacer()
            }
        }
        .padding(.top, 4)
    }
}
