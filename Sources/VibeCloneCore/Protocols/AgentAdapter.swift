import Foundation

public enum IPCKind: Sendable { case stdinStdout, sse, restPoll, jsPlugin }

public struct EventHandlingResult: Sendable {
    /// JSON body the bridge should write to stdout. `{}` for non-Permission events.
    public let stdoutJSON: Data
    public init(stdoutJSON: Data) { self.stdoutJSON = stdoutJSON }
}

public protocol AgentAdapter: Sendable {
    var id: String { get }                  // "claude-code", "codex", ...
    var displayName: String { get }
    var sourceFlag: String { get }          // value for --source <flag>
    var ipcKind: IPCKind { get }

    /// Install hook entries for all supported events into agent's config files.
    func installHooks(paths: Paths) throws

    /// Re-add missing hook entries. Returns true if any change applied.
    @discardableResult
    func healHooks(paths: Paths) throws -> Bool

    /// Parse raw stdin payload from the bridge into a typed event + payload.
    func decodeStdin(_ raw: Data) throws -> (event: EventName, payload: [String: JSONValue])

    /// Build the stdout body for the bridge given the app's decision for this event.
    /// For PermissionRequest, must include `hookSpecificOutput.permissionDecision`.
    /// For other events, return `Data("{}".utf8)`.
    func encodeStdoutBody(event: EventName, decision: ApprovalDecision?, reason: String?) throws -> Data
}
