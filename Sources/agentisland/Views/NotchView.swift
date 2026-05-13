import SwiftUI
import AgentIslandCore

enum NotchStyle: Equatable {
    case notch(NotchInfo)
    case bar
}

struct NotchView: View {
    @Bindable var controller: MenuBarController
    let style: NotchStyle
    @State private var pulseAttention: Bool = false

    /// Notch geometry — drives "drops out of notch" shape. nil for .bar.
    private var notchInfo: NotchInfo? {
        if case .notch(let info) = style, info.hasNotch { return info }
        return nil
    }

    /// Only expand when user clicks pill. Pending approvals + notices surface
    /// as badges on the pill — user opens manually.
    private var isExpanded: Bool { controller.notchExpanded }

    var body: some View {
        ZStack {
            if isExpanded {
                expandedSessionList
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85, anchor: .top)
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.92, anchor: .top)
                            .combined(with: .opacity)
                    ))
            } else {
                collapsed
                    .transition(.scale(scale: 1.05, anchor: .top)
                                .combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82, blendDuration: 0.2),
                   value: isExpanded)
        .fixedSize()
    }

    // MARK: - Collapsed (matches notch width, drops directly out of it)

    /// Compact pill: brand icon + top session title + count badge.
    /// Top inset = notch height when on a notched screen, else 0.
    /// Pill background extends from screen-top, hidden behind notch; content
    /// sits below the inset so it appears just under the notch.
    private var topInset: CGFloat { notchInfo?.notchHeight ?? 0 }

    /// Collapsed pill: enlarged notch shape. Left wing shows avatar + session
    /// title (truncated). Right wing shows notification + session count badges.
    /// Middle is hidden behind the camera carve on notched MBPs.
    private var collapsed: some View {
        let wing = max(60, (collapsedWidth - (notchInfo?.notchWidth ?? 0)) / 2)
        return Button {
            controller.notchExpanded = true
        } label: {
            HStack(spacing: 0) {
                // Left wing — avatar + name
                HStack(spacing: 6) {
                    if let top = controller.sessionCards.first {
                        AnimatedAvatar(brand: AgentBranding.brand(for: top.source),
                                       activity: top.activity)
                            .scaleEffect(0.55)
                            .frame(width: 18, height: 18)
                        Text(top.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else {
                        PixelLogoView(source: "claude",
                                      accent: .white.opacity(0.45),
                                      pixelSize: 2)
                            .frame(width: 16, height: 16)
                        Text("AgentIsland")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.leading, 10)
                .frame(width: wing, alignment: .leading)

                Spacer()

                // Right wing — counts
                HStack(spacing: 4) {
                    Spacer(minLength: 0)
                    if controller.pendingCount > 0 {
                        countBadge("\(controller.pendingCount)", tint: .red)
                            .scaleEffect(pulseAttention ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                       value: pulseAttention)
                            .onAppear { pulseAttention = true }
                    }
                    if !controller.notices.isEmpty {
                        countBadge("?", tint: .cyan)
                            .scaleEffect(pulseAttention ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                       value: pulseAttention)
                            .onAppear { pulseAttention = true }
                    }
                    if controller.sessionCards.count > 1 {
                        countBadge("\(controller.sessionCards.count)", tint: .white.opacity(0.22))
                    }
                }
                .padding(.trailing, 10)
                .frame(width: wing, alignment: .trailing)
            }
            .frame(width: collapsedWidth, height: collapsedHeight)
            .background(Capsule().fill(Color.black))
        }
        .buttonStyle(.plain)
    }

    private var collapsedHeight: CGFloat {
        notchInfo?.notchHeight ?? 28
    }

    @ViewBuilder
    private func countBadge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(Capsule().fill(tint))
    }

    /// Pill wider than the camera carve so its wings extend into visible
    /// menubar on either side of the notch. No-notch screens get a fixed bar.
    private var collapsedWidth: CGFloat {
        guard let info = notchInfo else { return 320 }
        return info.notchWidth + 220     // ~110pt visible wing per side
    }

    // MARK: - Expanded card — renders SessionListView

    private var expandedSessionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(controller.sessionCards.isEmpty ? "No active sessions" :
                     "\(controller.sessionCards.count) session\(controller.sessionCards.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button {
                    controller.notchExpanded = false
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Collapse")
            }
            SessionListView(controller: controller)
        }
        .padding(12)
        .frame(width: 420)
        .padding(.top, topInset)
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
