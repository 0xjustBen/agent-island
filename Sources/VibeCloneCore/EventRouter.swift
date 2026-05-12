import Foundation

/// History-write protocol — `HistoryWriter` (Task 12) will conform.
public protocol HistoryRecording: Sendable {
    func record(event: EventName, request: PermissionRequest,
                decision: ApprovalResponse, latencyMs: Int) async
}

public actor EventRouter {
    private let queue: ApprovalQueue
    private let sessions: ActiveSessions
    private let history: any HistoryRecording
    private let adapter: any AgentAdapter

    public var onEventArrived: (@Sendable (EventName) -> Void)?

    public func setOnEventArrived(_ closure: @escaping @Sendable (EventName) -> Void) {
        self.onEventArrived = closure
    }

    public init(queue: ApprovalQueue,
                sessions: ActiveSessions,
                history: any HistoryRecording,
                adapter: any AgentAdapter) {
        self.queue = queue
        self.sessions = sessions
        self.history = history
        self.adapter = adapter
    }

    /// Route a request for the given event. Always returns a stdout body for the bridge.
    public func route(event: EventName, request: PermissionRequest) async -> EventHandlingResult {
        onEventArrived?(event)
        let started = Date()
        switch event {
        case .permissionRequest:
            let resp = await queue.submitAndAwait(request)
            let body = (try? adapter.encodeStdoutBody(
                event: event,
                decision: resp.decision == .approve ? .approve : .deny,
                reason: resp.reason
            )) ?? Data("{}".utf8)
            await history.record(event: event, request: request, decision: resp,
                                 latencyMs: Int(Date().timeIntervalSince(started) * 1000))
            return EventHandlingResult(stdoutJSON: body)

        case .sessionStart:
            await sessions.start(sessionId: sessionId(from: request),
                                 source: request.source, locator: request.locator)

        case .sessionEnd, .stop:
            await sessions.end(sessionId: sessionId(from: request))

        case .subagentStart:
            await sessions.subagentDelta(sessionId: sessionId(from: request), delta: +1)

        case .subagentStop:
            await sessions.subagentDelta(sessionId: sessionId(from: request), delta: -1)

        case .preToolUse, .postToolUse, .notification, .userPromptSubmit, .preCompact:
            break   // record-only
        }

        await history.record(
            event: event, request: request,
            decision: ApprovalResponse(decision: .approve),
            latencyMs: Int(Date().timeIntervalSince(started) * 1000)
        )
        let body = (try? adapter.encodeStdoutBody(event: event, decision: nil, reason: nil))
            ?? Data("{}".utf8)
        return EventHandlingResult(stdoutJSON: body)
    }

    private func sessionId(from request: PermissionRequest) -> String {
        if case .string(let s) = request.payload["session_id"] ?? .null { return s }
        return request.id
    }
}
