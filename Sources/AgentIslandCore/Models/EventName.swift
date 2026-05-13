import Foundation

public enum EventName: String, Codable, CaseIterable, Sendable {
    case preToolUse        = "PreToolUse"
    case postToolUse       = "PostToolUse"
    case permissionRequest = "PermissionRequest"
    case notification      = "Notification"
    case userPromptSubmit  = "UserPromptSubmit"
    case sessionStart      = "SessionStart"
    case sessionEnd        = "SessionEnd"
    case stop              = "Stop"
    case subagentStart     = "SubagentStart"
    case subagentStop      = "SubagentStop"
    case preCompact        = "PreCompact"

    /// Matcher value used in CC settings.json. * for tool-bound events, "" otherwise.
    public var matcher: String {
        switch self {
        case .preToolUse, .postToolUse, .permissionRequest, .notification: return "*"
        default: return ""
        }
    }

    /// Hook timeout in seconds. PreToolUse blocks for human review.
    /// PermissionRequest is legacy (CC never emits it); kept for compatibility.
    public var timeoutSeconds: Int? {
        switch self {
        case .preToolUse, .permissionRequest: return 86_400
        default: return nil
        }
    }
}
