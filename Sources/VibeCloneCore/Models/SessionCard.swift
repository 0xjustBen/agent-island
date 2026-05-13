import Foundation

public struct SessionCard: Identifiable, Hashable, Sendable {
    public let id: String                  // session_id
    public var source: String              // claude / codex / gemini / ...
    public var terminalKind: ProbedTerminal
    public var title: String               // truncated first prompt, fallback "(no prompt)"
    public var lastPrompt: String?
    public var activity: Activity
    public var pendingPermission: PermissionRequest?
    public var pendingNotice: Notice?
    public var startedAt: Date
    public var lastActiveAt: Date

    public enum Activity: Hashable, Sendable {
        case idle
        case runningTool(name: String, description: String?)
        case justFinished(toolName: String)
    }

    public init(id: String, source: String, terminalKind: ProbedTerminal,
                title: String, lastPrompt: String?, activity: Activity,
                pendingPermission: PermissionRequest?, pendingNotice: Notice?,
                startedAt: Date, lastActiveAt: Date) {
        self.id = id; self.source = source; self.terminalKind = terminalKind
        self.title = title; self.lastPrompt = lastPrompt; self.activity = activity
        self.pendingPermission = pendingPermission; self.pendingNotice = pendingNotice
        self.startedAt = startedAt; self.lastActiveAt = lastActiveAt
    }
}
