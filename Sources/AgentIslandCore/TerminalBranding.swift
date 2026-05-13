import Foundation

public enum TerminalBranding {
    public static func displayName(for kind: ProbedTerminal) -> String {
        switch kind {
        case .iTerm2:      return "iTerm"
        case .terminalApp: return "Terminal"
        case .ghostty:     return "Ghostty"
        case .warp:        return "Warp"
        case .vscode:      return "VS Code"
        case .cursor:      return "Cursor"
        case .alacritty:   return "Alacritty"
        case .kitty:       return "kitty"
        case .tmux:        return "tmux"
        case .unknown:     return "Terminal"
        }
    }
}
