import SwiftUI
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
        }
        .padding(.top, 4)
    }
}
