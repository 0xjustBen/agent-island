import SwiftUI

struct Chip: View {
    let text: String
    var systemImage: String? = nil
    var color: Color = .white.opacity(0.10)

    var body: some View {
        HStack(spacing: 4) {
            if let img = systemImage {
                Image(systemName: img).font(.system(size: 9))
            }
            Text(text).font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(color))
        .foregroundStyle(.white.opacity(0.95))
    }
}
