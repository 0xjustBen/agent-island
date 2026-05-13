import Foundation

public struct AgentBrand: Hashable, Sendable {
    public let id: String
    public let emoji: String
    public let symbolName: String      // SF Symbol approximating each brand
    public let displayName: String
    public let accentHex: String       // brand-accurate accent hex
    public init(id: String, emoji: String, symbolName: String,
                displayName: String, accentHex: String) {
        self.id = id; self.emoji = emoji; self.symbolName = symbolName
        self.displayName = displayName; self.accentHex = accentHex
    }
}

public enum AgentBranding {
    public static let all: [String: AgentBrand] = [
        "claude":    AgentBrand(id: "claude",    emoji: "👻", symbolName: "sparkles",                                  displayName: "Claude",    accentHex: "#d97757"),
        "codex":     AgentBrand(id: "codex",     emoji: "🔷", symbolName: "cpu",                                       displayName: "Codex",     accentHex: "#10a37f"),
        "gemini":    AgentBrand(id: "gemini",    emoji: "🟢", symbolName: "atom",                                      displayName: "Gemini",    accentHex: "#4285f4"),
        "cursor":    AgentBrand(id: "cursor",    emoji: "⚡", symbolName: "cursorarrow.rays",                          displayName: "Cursor",    accentHex: "#bf5af2"),
        "opencode":  AgentBrand(id: "opencode",  emoji: "🐙", symbolName: "chevron.left.forwardslash.chevron.right",   displayName: "OpenCode",  accentHex: "#8e8e93"),
        "droid":     AgentBrand(id: "droid",     emoji: "🤖", symbolName: "ladybug.fill",                              displayName: "Droid",     accentHex: "#ff9f0a"),
        "qoder":     AgentBrand(id: "qoder",     emoji: "🔶", symbolName: "diamond.fill",                              displayName: "Qoder",     accentHex: "#ffd60a"),
        "qwen":      AgentBrand(id: "qwen",      emoji: "🌀", symbolName: "hurricane",                                 displayName: "Qwen",      accentHex: "#5e5ce6"),
        "copilot":   AgentBrand(id: "copilot",   emoji: "🚁", symbolName: "airplane",                                  displayName: "Copilot",   accentHex: "#64d2ff"),
        "codebuddy": AgentBrand(id: "codebuddy", emoji: "🐧", symbolName: "person.2.fill",                             displayName: "CodeBuddy", accentHex: "#ac8e68"),
        "kiro":      AgentBrand(id: "kiro",      emoji: "🦊", symbolName: "pawprint.fill",                             displayName: "Kiro",      accentHex: "#ff453a"),
        "kimi":      AgentBrand(id: "kimi",      emoji: "🌙", symbolName: "moon.stars.fill",                           displayName: "Kimi",      accentHex: "#0a84ff"),
        "deepseek":  AgentBrand(id: "deepseek",  emoji: "🐳", symbolName: "water.waves",                               displayName: "DeepSeek",  accentHex: "#1e6fff"),
    ]

    public static func brand(for source: String) -> AgentBrand {
        if let b = all[source.lowercased()] { return b }
        return AgentBrand(id: source, emoji: "💻", symbolName: "terminal.fill",
                          displayName: source.capitalized, accentHex: "#8e8e93")
    }
}
