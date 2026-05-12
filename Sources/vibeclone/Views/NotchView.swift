import SwiftUI
import VibeCloneCore

enum NotchStyle: Equatable {
    case notch(NotchInfo)
    case bar
}

struct NotchView: View {
    @Bindable var controller: MenuBarController
    let style: NotchStyle

    var body: some View {
        Group {
            if let req = controller.pending.first {
                expanded(req: req, more: max(controller.pendingCount - 1, 0))
            } else {
                collapsed
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7),
                   value: controller.pendingCount)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 400)
        .padding(.top, topPadding)
    }

    // MARK: - Collapsed

    private var collapsed: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(controller.activeSessionsCount > 0 ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
            Text(idleText).font(.caption2.monospaced())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Capsule().fill(.black.opacity(0.85)))
        .foregroundStyle(.white)
    }

    private var idleText: String {
        if controller.activeSessionsCount > 0 {
            return "\(controller.activeSessionsCount) active"
        }
        return "vibeclone"
    }

    // MARK: - Expanded

    private func expanded(req: PermissionRequest, more: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(req.source).bold()
                Text("·").foregroundStyle(.secondary)
                Text(toolName(req)).font(.system(.body, design: .monospaced))
                Spacer()
                if more > 0 {
                    Text("+\(more) more")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            preview(req)
            HStack {
                Button("Jump") { controller.jump(req) }
                Spacer()
                Button("Deny", role: .destructive) { controller.deny(req) }
                Button("Approve") { controller.approve(req) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(14)
        .frame(width: 380)
        .background(RoundedRectangle(cornerRadius: 18).fill(.black.opacity(0.88)))
        .foregroundStyle(.white)
    }

    private func toolName(_ r: PermissionRequest) -> String {
        if case .string(let s) = r.payload["tool_name"] ?? .null { return s }
        return "?"
    }

    @ViewBuilder
    private func preview(_ r: PermissionRequest) -> some View {
        if let md = planSource(r) {
            Text(MarkdownRenderer.render(md))
                .lineLimit(5)
                .font(.callout)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.10)))
        } else {
            let text: String = {
                if case .object(let input) = r.payload["tool_input"] ?? .null,
                   case .string(let cmd) = input["command"] ?? .null {
                    return cmd
                }
                return ""
            }()
            Text(text)
                .lineLimit(3)
                .font(.system(.callout, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.10)))
        }
    }

    private func planSource(_ r: PermissionRequest) -> String? {
        if case .object(let input) = r.payload["tool_input"] ?? .null {
            if case .string(let s) = input["plan"] ?? .null, s.count > 20 { return s }
            if case .string(let s) = input["prompt"] ?? .null, s.count > 60 { return s }
        }
        if case .string(let s) = r.payload["plan"] ?? .null, s.count > 20 { return s }
        return nil
    }

    // MARK: - Top padding tuning

    private var topPadding: CGFloat {
        switch style {
        case .notch(let info): return max(info.notchHeight, 8) + 4
        case .bar: return 4
        }
    }
}
