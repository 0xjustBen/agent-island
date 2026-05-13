import SwiftUI
import AgentIslandCore

/// 8x8 pixel-art logos approximating each AI company's brand mark.
/// Copyright-safe: original pixel-art interpretations, not actual logos.
/// `1` = accent color, `2` = white, `0` = transparent.
enum PixelLogo {

    /// 8x8 grids per agent. Use the agent's `accentHex` as the colored pixel.
    static let grids: [String: [[Int]]] = [
        // Claude — ghost mascot (Anthropic's unofficial ghost)
        "claude": [
            [0,0,1,1,1,1,0,0],
            [0,1,1,1,1,1,1,0],
            [1,1,2,1,1,2,1,1],
            [1,1,2,1,1,2,1,1],
            [1,1,1,1,1,1,1,1],
            [1,1,1,1,1,1,1,1],
            [1,0,1,0,1,0,1,0],
            [0,0,0,0,0,0,0,0],
        ],
        // Codex / OpenAI — hex flower (6-fold rosette)
        "codex": [
            [0,0,1,1,1,1,0,0],
            [0,1,0,0,0,0,1,0],
            [1,0,1,0,0,1,0,1],
            [1,0,0,1,1,0,0,1],
            [1,0,0,1,1,0,0,1],
            [1,0,1,0,0,1,0,1],
            [0,1,0,0,0,0,1,0],
            [0,0,1,1,1,1,0,0],
        ],
        // Gemini — 4-pointed sparkle star
        "gemini": [
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,1,1,1,1,0,0],
            [1,1,1,1,1,1,1,1],
            [1,1,1,1,1,1,1,1],
            [0,0,1,1,1,1,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
        ],
        // Cursor — lightning bolt
        "cursor": [
            [0,0,0,1,1,1,0,0],
            [0,0,1,1,1,0,0,0],
            [0,1,1,1,0,0,0,0],
            [1,1,1,1,1,1,1,0],
            [0,1,1,1,1,1,1,0],
            [0,0,0,0,1,1,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,1,1,0,0,0,0],
        ],
        // OpenCode — `</>` braces
        "opencode": [
            [0,1,0,0,0,0,1,0],
            [1,0,0,0,0,0,0,1],
            [1,0,0,0,1,0,0,1],
            [1,0,0,1,0,0,0,1],
            [1,0,0,1,0,0,0,1],
            [1,0,0,0,1,0,0,1],
            [1,0,0,0,0,0,0,1],
            [0,1,0,0,0,0,1,0],
        ],
        // Droid / Factory — robot face
        "droid": [
            [0,0,1,1,1,1,0,0],
            [0,1,1,1,1,1,1,0],
            [1,1,2,1,1,2,1,1],
            [1,1,1,1,1,1,1,1],
            [1,1,1,2,2,1,1,1],
            [1,1,1,1,1,1,1,1],
            [0,1,0,0,0,0,1,0],
            [0,1,0,0,0,0,1,0],
        ],
        // Qoder — diamond
        "qoder": [
            [0,0,0,1,1,0,0,0],
            [0,0,1,1,1,1,0,0],
            [0,1,1,1,1,1,1,0],
            [1,1,1,1,1,1,1,1],
            [1,1,1,1,1,1,1,1],
            [0,1,1,1,1,1,1,0],
            [0,0,1,1,1,1,0,0],
            [0,0,0,1,1,0,0,0],
        ],
        // Qwen — spiral
        "qwen": [
            [0,1,1,1,1,1,1,0],
            [1,0,0,0,0,0,0,1],
            [1,0,1,1,1,1,0,1],
            [1,0,1,0,0,1,0,1],
            [1,0,1,0,1,1,0,1],
            [1,0,1,1,1,0,0,1],
            [1,0,0,0,0,0,0,1],
            [0,1,1,1,1,1,1,0],
        ],
        // Copilot — paper airplane
        "copilot": [
            [0,0,0,0,0,0,0,1],
            [0,0,0,0,0,0,1,1],
            [0,0,0,0,0,1,1,1],
            [1,1,1,1,1,1,1,1],
            [1,1,1,1,1,1,1,0],
            [0,0,0,0,1,1,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,1,1,0,0,0,0],
        ],
        // CodeBuddy — two figures
        "codebuddy": [
            [0,1,1,0,0,1,1,0],
            [0,1,1,0,0,1,1,0],
            [1,1,1,1,1,1,1,1],
            [1,2,1,1,1,1,2,1],
            [1,1,1,1,1,1,1,1],
            [0,1,1,1,1,1,1,0],
            [0,1,1,0,0,1,1,0],
            [0,1,1,0,0,1,1,0],
        ],
        // Kiro — fox face (triangle ears)
        "kiro": [
            [1,0,0,0,0,0,0,1],
            [1,1,0,0,0,0,1,1],
            [1,1,1,1,1,1,1,1],
            [1,2,1,1,1,1,2,1],
            [1,1,1,2,2,1,1,1],
            [1,1,1,1,1,1,1,1],
            [0,1,1,1,1,1,1,0],
            [0,0,1,1,1,1,0,0],
        ],
        // Kimi — crescent moon
        "kimi": [
            [0,0,1,1,1,1,0,0],
            [0,1,1,0,0,1,1,0],
            [1,1,0,0,0,0,1,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,1,0],
            [0,1,1,0,0,1,1,0],
            [0,0,1,1,1,1,0,0],
        ],
        // DeepSeek — whale
        "deepseek": [
            [0,0,0,1,1,0,0,0],
            [0,0,1,1,1,1,0,0],
            [0,1,1,1,1,1,1,0],
            [1,1,1,2,1,1,1,1],
            [1,1,1,1,1,1,1,1],
            [0,1,1,1,1,1,1,0],
            [0,0,1,0,0,1,0,0],
            [0,0,0,0,0,0,0,0],
        ],
    ]

    static func grid(for source: String) -> [[Int]] {
        if let g = grids[source.lowercased()] { return g }
        // Fallback — 8x8 filled square outline.
        return [
            [1,1,1,1,1,1,1,1],
            [1,0,0,0,0,0,0,1],
            [1,0,1,1,1,1,0,1],
            [1,0,1,0,0,1,0,1],
            [1,0,1,0,0,1,0,1],
            [1,0,1,1,1,1,0,1],
            [1,0,0,0,0,0,0,1],
            [1,1,1,1,1,1,1,1],
        ]
    }
}

struct PixelLogoView: View {
    let source: String
    let accent: Color
    let pixelSize: CGFloat

    init(source: String, accent: Color, pixelSize: CGFloat = 2) {
        self.source = source; self.accent = accent; self.pixelSize = pixelSize
    }

    var body: some View {
        let grid = PixelLogo.grid(for: source)
        VStack(spacing: 0) {
            ForEach(0..<grid.count, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<grid[row].count, id: \.self) { col in
                        Rectangle()
                            .fill(color(for: grid[row][col]))
                            .frame(width: pixelSize, height: pixelSize)
                    }
                }
            }
        }
        .drawingGroup()           // rasterize the grid for crisp pixels
    }

    private func color(for value: Int) -> Color {
        switch value {
        case 1: return accent
        case 2: return .white
        default: return .clear
        }
    }
}
