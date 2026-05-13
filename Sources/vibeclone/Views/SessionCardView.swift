import SwiftUI
import VibeCloneCore

struct SessionCardView: View {
    let card: SessionCard
    let onJump: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let prompt = card.lastPrompt, !prompt.isEmpty {
                    Text("You: \(prompt)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }
                activityLine
                HStack(spacing: 4) {
                    Chip(text: brand.displayName, color: .white.opacity(0.12))
                    Chip(text: terminalName, color: .white.opacity(0.12))
                    Text("· last activity \(TimeAgo.format(card.lastActiveAt))")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.top, 2)
            }
            Spacer()
            Button(action: onJump) {
                Label("Jump", systemImage: "arrow.up.forward.app.fill")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: brand.accentHex).opacity(0.85))
            .controlSize(.small)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.06)))
    }

    private var brand: AgentBrand { AgentBranding.brand(for: card.source) }
    private var terminalName: String { TerminalBranding.displayName(for: card.terminalKind) }

    private var avatar: some View {
        AnimatedAvatar(brand: brand, activity: card.activity)
    }

    @ViewBuilder
    private var activityLine: some View {
        switch card.activity {
        case .idle:
            EmptyView()
        case .runningTool(_, let desc):
            Text(desc ?? "Working…")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: brand.accentHex))
        case .justFinished:
            Text("Done — click to jump")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.green)
        }
    }
}

/// Quick Color(hex:) extension.
extension Color {
    init(hex: String) {
        var h = hex
        if h.hasPrefix("#") { h.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xff) / 255
        let g = Double((rgb >> 8) & 0xff) / 255
        let b = Double(rgb & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}
