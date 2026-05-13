import SwiftUI
import AgentIslandCore

/// Animated agent avatar: emoji centered on a tinted ring. While the session
/// is running a tool, the ring rotates slowly and the emoji pulses. While
/// "just finished" the ring flashes green. While idle, static.
struct AnimatedAvatar: View {
    let brand: AgentBrand
    let activity: SessionCard.Activity

    @State private var rotate: Double = 0
    @State private var pulse: Bool = false

    private var working: Bool {
        if case .runningTool = activity { return true }
        return false
    }
    private var finished: Bool {
        if case .justFinished = activity { return true }
        return false
    }

    var body: some View {
        ZStack {
            // Outer animated ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: working
                            ? [accent, accent.opacity(0.1), accent]
                            : (finished ? [.green, .green.opacity(0.2), .green] : [accent.opacity(0.35)]),
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(rotate))
                .animation(
                    working
                        ? .linear(duration: 2.2).repeatForever(autoreverses: false)
                        : .default,
                    value: rotate
                )

            // Inner fill
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: 24, height: 24)

            // Pixel-art brand logo
            PixelLogoView(source: brand.id, accent: accent, pixelSize: 2)
                .scaleEffect(pulse ? 1.10 : 1.0)
                .animation(
                    working
                        ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                        : .default,
                    value: pulse
                )
        }
        .onAppear { startAnimations() }
        .onChange(of: working) { _, _ in startAnimations() }
    }

    private var accent: Color { Color(hex: brand.accentHex) }

    private func startAnimations() {
        if working {
            rotate = 360
            pulse = true
        } else {
            rotate = 0
            pulse = false
        }
    }
}
