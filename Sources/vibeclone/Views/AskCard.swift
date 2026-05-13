import SwiftUI
import VibeCloneCore

struct AskCard: View {
    let card: SessionCard
    let notice: Notice
    let parsed: AskParseResult?
    let onPick: (AskOption) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bubble.left.fill").foregroundStyle(.cyan)
                Text("\(AgentBranding.brand(for: card.source).displayName) asks")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.cyan)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain).foregroundStyle(.white.opacity(0.5))
            }
            Text(parsed?.question ?? notice.message)
                .font(.system(size: 14))
                .foregroundStyle(.white)
            if let parsed, !parsed.options.isEmpty {
                VStack(spacing: 6) {
                    ForEach(parsed.options, id: \.number) { opt in
                        Button { onPick(opt) } label: {
                            HStack(spacing: 8) {
                                Text("⌘\(opt.number)")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(.cyan.opacity(0.18)))
                                    .foregroundStyle(.cyan)
                                Text(opt.label)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(KeyEquivalent(Character("\(opt.number)")), modifiers: .command)
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.6)))
    }
}
