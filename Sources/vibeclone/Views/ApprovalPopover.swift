import SwiftUI
import VibeCloneCore

struct ApprovalPopover: View {
    @Bindable var controller: MenuBarController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Divider()
            requestList
            Divider()
            EventTicker(activeSessions: controller.activeSessionsCount,
                        lastEventAt: controller.lastEventAt)
            footer
        }
        .padding(12)
        .frame(width: 460)
    }

    private var header: some View {
        HStack {
            Text("VibeClone").font(.headline)
            Spacer()
            Text("Pending: \(controller.pendingCount)")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var requestList: some View {
        if controller.pending.isEmpty {
            Text("No pending requests.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(controller.pending, id: \.id) { req in
                        RequestRow(
                            request: req,
                            onApprove: { controller.approve(req) },
                            onDeny:    { controller.deny(req) },
                            onJump:    { controller.jump(req) }
                        )
                    }
                }
            }
            .frame(maxHeight: 360)
        }
    }

    private var footer: some View {
        HStack {
            Toggle("Auto-heal hooks", isOn: Binding(
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
        .padding(.top, 4)
    }
}
