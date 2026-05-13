import Foundation

public actor SessionAggregator {
    /// Pluggable terminal probe — default uses live macOS process tree.
    private let probe: @Sendable (pid_t) -> ProbedTerminal
    private var sessions: [String: SessionCard] = [:]

    public init(probe: @escaping @Sendable (pid_t) -> ProbedTerminal = { pid in
        TerminalProber.probeLive(startPid: pid)
    }) {
        self.probe = probe
    }

    /// Accept an event from the router. Updates `sessions` accordingly.
    public func accept(event: EventName, request: PermissionRequest, notice: Notice? = nil) {
        let now = Date()
        let sid = sessionId(from: request)
        var card = sessions[sid] ?? SessionCard(
            id: sid, source: request.source,
            terminalKind: request.locator.ppid.map(probe) ?? .unknown,
            title: "(no prompt)", lastPrompt: nil,
            activity: .idle, pendingPermission: nil, pendingNotice: nil,
            startedAt: now, lastActiveAt: now,
            lastLocator: request.locator
        )
        card.lastActiveAt = now
        card.lastLocator = request.locator
        // Refresh terminal kind if we now have a ppid.
        if card.terminalKind == .unknown, let ppid = request.locator.ppid {
            card.terminalKind = probe(ppid)
        }

        switch event {
        case .sessionStart:
            // Already initialized above; nothing extra.
            break

        case .sessionEnd, .stop:
            sessions.removeValue(forKey: sid)
            return

        case .userPromptSubmit:
            let text = (extractString(request.payload, key: "prompt")
                     ?? extractString(request.payload, key: "user_prompt")
                     ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                card.lastPrompt = text
                if card.title == "(no prompt)" {
                    card.title = String(text.prefix(60))
                }
            }

        case .preToolUse:
            let toolName = extractString(request.payload, key: "tool_name") ?? "?"
            let desc = describeTool(toolName: toolName, request: request)
            card.activity = .runningTool(name: toolName, description: desc)

        case .postToolUse:
            let toolName = extractString(request.payload, key: "tool_name") ?? "?"
            card.activity = .justFinished(toolName: toolName)

        case .permissionRequest:
            card.pendingPermission = request

        case .notification:
            if let n = notice {
                card.pendingNotice = n
            }

        case .subagentStart, .subagentStop, .preCompact:
            break
        }
        sessions[sid] = card
    }

    /// Clear pending permission for a session (after user resolves it).
    public func clearPendingPermission(sessionId: String) {
        if var card = sessions[sessionId] {
            card.pendingPermission = nil
            sessions[sessionId] = card
        }
    }

    /// Clear pending notice for a session (after user dismisses it).
    public func clearPendingNotice(sessionId: String) {
        if var card = sessions[sessionId] {
            card.pendingNotice = nil
            sessions[sessionId] = card
        }
    }

    /// Demote "just finished" → idle after `cooldownSeconds`. Call periodically.
    public func ageActivities(cooldownSeconds: TimeInterval = 5) {
        let cutoff = Date().addingTimeInterval(-cooldownSeconds)
        for (sid, card) in sessions {
            if case .justFinished = card.activity, card.lastActiveAt < cutoff {
                var c = card
                c.activity = .idle
                sessions[sid] = c
            }
        }
    }

    public func snapshot() -> [SessionCard] {
        // Most recently active first.
        sessions.values.sorted { $0.lastActiveAt > $1.lastActiveAt }
    }

    // MARK: - Helpers

    private func sessionId(from request: PermissionRequest) -> String {
        if case .string(let s) = request.payload["session_id"] ?? .null { return s }
        return request.id
    }

    private func extractString(_ payload: [String: JSONValue], key: String) -> String? {
        if case .string(let s) = payload[key] ?? .null { return s }
        // Nested under tool_input?
        if case .object(let input) = payload["tool_input"] ?? .null,
           case .string(let s) = input[key] ?? .null { return s }
        return nil
    }

    /// Pretty-print activity description for common CC tools.
    private func describeTool(toolName: String, request: PermissionRequest) -> String? {
        guard case .object(let input) = request.payload["tool_input"] ?? .null else { return nil }
        switch toolName {
        case "Bash":
            if case .string(let cmd) = input["command"] ?? .null {
                return String(cmd.prefix(60))
            }
        case "Edit", "Write":
            if case .string(let path) = input["file_path"] ?? .null {
                let base = (path as NSString).lastPathComponent
                return "\(toolName == "Edit" ? "Editing" : "Writing") \(base)"
            }
        case "Read":
            if case .string(let path) = input["file_path"] ?? .null {
                return "Reading \((path as NSString).lastPathComponent)"
            }
        default:
            break
        }
        return nil
    }
}
