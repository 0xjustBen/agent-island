import SwiftUI
import VibeCloneCore

enum NotchStyle: Equatable {
    case notch(NotchInfo)
    case bar
}

struct NotchView: View {
    @Bindable var controller: MenuBarController
    let style: NotchStyle

    /// Notch geometry — drives "drops out of notch" shape. nil for .bar.
    private var notchInfo: NotchInfo? {
        if case .notch(let info) = style, info.hasNotch { return info }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: topClearance)
            HStack {
                Spacer(minLength: 0)
                Group {
                    if !controller.sessionCards.isEmpty &&
                       (controller.pendingCount > 0 || controller.notices.count > 0) {
                        expandedSessionList
                    } else {
                        collapsed
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.78),
                           value: controller.pendingCount)
                .fixedSize()
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Collapsed (matches notch width, drops directly out of it)

    private var collapsed: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(controller.sessionCards.count > 0 ? Color.green : Color.gray.opacity(0.6))
                .frame(width: 6, height: 6)
            if controller.sessionCards.count > 0 {
                Text("\(controller.sessionCards.count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .frame(width: collapsedWidth, height: 14)
        .background(notchPill(radius: 10))
    }

    /// Width matches notch underside so visually it IS the notch dropping down.
    private var collapsedWidth: CGFloat {
        if let info = notchInfo { return info.notchWidth + 4 }
        return 200
    }

    // MARK: - Expanded card — renders SessionListView

    private var expandedSessionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            SessionListView(controller: controller)
        }
        .padding(12)
        .frame(width: 420)
        .background(notchPill(radius: 22))
        .foregroundStyle(.white)
    }

    // MARK: - Shape — top corners flush with notch, bottom corners rounded

    @ViewBuilder
    private func notchPill(radius: CGFloat) -> some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: radius,
            bottomTrailingRadius: radius,
            topTrailingRadius: 0,
            style: .continuous
        )
        .fill(Color.black)
    }

    // MARK: - Helpers

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
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.10)))
                .foregroundStyle(.white)
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
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.10)))
                .foregroundStyle(.white)
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

    private var topClearance: CGFloat {
        switch style {
        case .notch(let info): return info.notchHeight     // flush with notch bottom
        case .bar: return 28                                // below menu bar
        }
    }
}
