import Foundation

public struct AgentBrand: Hashable, Sendable {
    public let id: String
    public let emoji: String
    public let displayName: String
    public let accentHex: String       // hex color like "#34c759"
    public init(id: String, emoji: String, displayName: String, accentHex: String) {
        self.id = id; self.emoji = emoji; self.displayName = displayName
        self.accentHex = accentHex
    }
}

public enum AgentBranding {
    public static let all: [String: AgentBrand] = [
        "claude":    AgentBrand(id: "claude",    emoji: "👻", displayName: "Claude",    accentHex: "#34c759"),
        "codex":     AgentBrand(id: "codex",     emoji: "🔷", displayName: "Codex",     accentHex: "#0a84ff"),
        "gemini":    AgentBrand(id: "gemini",    emoji: "🟢", displayName: "Gemini",    accentHex: "#30d158"),
        "cursor":    AgentBrand(id: "cursor",    emoji: "⚡", displayName: "Cursor",    accentHex: "#bf5af2"),
        "opencode":  AgentBrand(id: "opencode",  emoji: "🐙", displayName: "OpenCode",  accentHex: "#8e8e93"),
        "droid":     AgentBrand(id: "droid",     emoji: "🤖", displayName: "Droid",     accentHex: "#ff9f0a"),
        "qoder":     AgentBrand(id: "qoder",     emoji: "🔶", displayName: "Qoder",     accentHex: "#ffd60a"),
        "qwen":      AgentBrand(id: "qwen",      emoji: "🌀", displayName: "Qwen",      accentHex: "#5e5ce6"),
        "copilot":   AgentBrand(id: "copilot",   emoji: "🚁", displayName: "Copilot",   accentHex: "#64d2ff"),
        "codebuddy": AgentBrand(id: "codebuddy", emoji: "🐧", displayName: "CodeBuddy", accentHex: "#ac8e68"),
        "kiro":      AgentBrand(id: "kiro",      emoji: "🦊", displayName: "Kiro",      accentHex: "#ff453a"),
        "kimi":      AgentBrand(id: "kimi",      emoji: "🌙", displayName: "Kimi",      accentHex: "#0a84ff"),
        "deepseek":  AgentBrand(id: "deepseek",  emoji: "🐳", displayName: "DeepSeek",  accentHex: "#0a84ff"),
    ]

    public static func brand(for source: String) -> AgentBrand {
        if let b = all[source.lowercased()] { return b }
        return AgentBrand(id: source, emoji: "💻",
                          displayName: source.capitalized, accentHex: "#8e8e93")
    }
}
