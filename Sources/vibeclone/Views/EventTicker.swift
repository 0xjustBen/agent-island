import SwiftUI
import VibeCloneCore

struct EventTicker: View {
    let activeSessions: Int
    let lastEventAt: Date?

    var body: some View {
        HStack(spacing: 12) {
            Label("\(activeSessions) session\(activeSessions == 1 ? "" : "s") active",
                  systemImage: "circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(activeSessions > 0 ? .green : .secondary)
                .font(.caption)
            Spacer()
            if let when = lastEventAt {
                Text("Last event: \(relativeText(from: when))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func relativeText(from date: Date) -> String {
        let secs = Int(Date().timeIntervalSince(date))
        if secs < 5 { return "just now" }
        if secs < 60 { return "\(secs)s ago" }
        if secs < 3600 { return "\(secs / 60)m ago" }
        return "\(secs / 3600)h ago"
    }
}
