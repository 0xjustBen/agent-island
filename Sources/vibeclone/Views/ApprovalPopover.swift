import SwiftUI
import VibeCloneCore

struct ApprovalPopover: View {
    @Bindable var controller: MenuBarController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Divider()
            if !controller.notices.isEmpty {
                noticesList
                Divider()
            }
            requestList
            Divider()
            EventTicker(activeSessions: controller.activeSessionsCount,
                        lastEventAt: controller.lastEventAt)
            footer
        }
        .padding(12)
        .frame(width: 460)
    }

    @ViewBuilder private var noticesList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notifications").font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(controller.notices, id: \.id) { n in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "bell.fill").foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(n.source).font(.caption.weight(.semibold))
                        Text(n.message).font(.callout).lineLimit(3)
                    }
                    Spacer()
                    Button("Jump") { controller.jumpNotice(n) }
                        .buttonStyle(.bordered).controlSize(.small)
                    Button {
                        controller.dismissNotice(n)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(.yellow.opacity(0.10)))
            }
        }
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
        .padding(.top, 4)
    }
}
