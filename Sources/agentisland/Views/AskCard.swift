import SwiftUI
import AgentIslandCore

struct AskCard: View {
    let card: SessionCard
    let notice: Notice
    let parsed: AskParseResult?
    let onPick: (AskOption) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.cyan)
                Text("\(AgentBranding.brand(for: card.source).displayName) asks")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.cyan)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain).foregroundStyle(.white.opacity(0.5))
            }
            Text(parsed?.question ?? notice.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            if let parsed, !parsed.options.isEmpty {
                VStack(spacing: 8) {
                    ForEach(parsed.options, id: \.number) { opt in
                        Button { onPick(opt) } label: {
                            HStack(alignment: .top, spacing: 10) {
                                cmdBadge(opt.number)
                                VStack(alignment: .leading, spacing: 2) {
                                    let (label, desc) = splitLabel(opt.label)
                                    Text(label)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    if let desc {
                                        Text(desc)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.6))
                                            .lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.10)))
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(KeyEquivalent(Character("\(opt.number)")), modifiers: .command)
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black))
    }

    /// AskOptionParser stores "label — description" in one string when the
    /// aggregator synthesized it from AskUserQuestion. Split for two-line UI.
    private func splitLabel(_ raw: String) -> (String, String?) {
        if let r = raw.range(of: " — ") {
            return (String(raw[..<r.lowerBound]), String(raw[r.upperBound...]))
        }
        return (raw, nil)
    }

    private func cmdBadge(_ n: Int) -> some View {
        HStack(spacing: 1) {
            Image(systemName: "command")
                .font(.system(size: 10, weight: .bold))
            Text("\(n)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.cyan)
        .padding(.horizontal, 7).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 6).fill(.cyan.opacity(0.18)))
    }
}
