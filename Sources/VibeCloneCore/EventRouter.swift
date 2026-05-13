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
    private let notices: NoticeStore?
    private let aggregator: SessionAggregator?
    private let quota: QuotaTracker?

    public var onEventArrived: (@Sendable (EventName) -> Void)?

    public func setOnEventArrived(_ closure: @escaping @Sendable (EventName) -> Void) {
        self.onEventArrived = closure
    }

    public init(queue: ApprovalQueue,
                sessions: ActiveSessions,
                history: any HistoryRecording,
                adapter: any AgentAdapter,
                notices: NoticeStore? = nil,
                aggregator: SessionAggregator? = nil,
                quota: QuotaTracker? = nil) {
        self.queue = queue
        self.sessions = sessions
        self.history = history
        self.adapter = adapter
        self.notices = notices
        self.aggregator = aggregator
        self.quota = quota
    }

    /// Route a request for the given event. Always returns a stdout body for the bridge.
    public func route(event: EventName, request: PermissionRequest) async -> EventHandlingResult {
        onEventArrived?(event)
        let started = Date()
        switch event {
        case .permissionRequest:
            if let agg = aggregator {
                await agg.accept(event: event, request: request, notice: nil)
            }
            let resp = await queue.submitAndAwait(request)
            let body = (try? adapter.encodeStdoutBody(
                event: event,
                decision: resp.decision == .approve ? .approve : .deny,
                reason: resp.reason
            )) ?? Data("{}".utf8)
            await history.record(event: event, request: request, decision: resp,
                                 latencyMs: Int(Date().timeIntervalSince(started) * 1000))
            if let agg = aggregator {
                await agg.clearPendingPermission(sessionId: sessionId(from: request))
            }
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

        case .notification:
            if let store = notices {
                let msg = extractMessage(from: request) ?? "Agent is waiting"
                await store.add(Notice(
                    id: request.id, source: request.source, message: msg,
                    locator: request.locator, receivedAt: Date()
                ))
            }

        case .preToolUse, .postToolUse, .userPromptSubmit, .preCompact:
            break   // record-only
        }

        await history.record(
            event: event, request: request,
            decision: ApprovalResponse(decision: .approve),
            latencyMs: Int(Date().timeIntervalSince(started) * 1000)
        )
        if let quota = quota {
            await quota.ingest(event: event, request: request)
        }
        if let agg = aggregator {
            var noticeForAgg: Notice? = nil
            if event == .notification, let store = notices {
                let snap = await store.snapshot()
                noticeForAgg = snap.first { $0.id == request.id }
            }
            await agg.accept(event: event, request: request, notice: noticeForAgg)
        }
        let body = (try? adapter.encodeStdoutBody(event: event, decision: nil, reason: nil))
            ?? Data("{}".utf8)
        return EventHandlingResult(stdoutJSON: body)
    }

    private func sessionId(from request: PermissionRequest) -> String {
        if case .string(let s) = request.payload["session_id"] ?? .null { return s }
        return request.id
    }

    private func extractMessage(from request: PermissionRequest) -> String? {
        if case .string(let m) = request.payload["message"] ?? .null { return m }
        if case .string(let m) = request.payload["text"] ?? .null { return m }
        return nil
    }
}
