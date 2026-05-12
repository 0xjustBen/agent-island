import Foundation

public actor ApprovalQueue {
    struct Pending {
        let request: PermissionRequest
        let continuation: CheckedContinuation<ApprovalResponse, Never>
        let dedupKey: String
    }

    private var pending: [String: Pending] = [:]
    private var recentDecisions: [String: (decision: ApprovalResponse, at: Date)] = [:]
    private let timeout: Duration
    private let dedupWindow: Duration

    public init(timeout: Duration = .seconds(86_400),
                dedupWindow: Duration = .seconds(5)) {
        self.timeout = timeout
        self.dedupWindow = dedupWindow
    }

    public var pendingCount: Int { pending.count }
    public var pendingList: [PermissionRequest] { pending.values.map(\.request) }

    public func submitAndAwait(_ request: PermissionRequest) async -> ApprovalResponse {
        let key = request.dedupKey
        if let recent = recentDecisions[key],
           Date().timeIntervalSince(recent.at) < seconds(dedupWindow) {
            return recent.decision
        }
        return await withCheckedContinuation { (c: CheckedContinuation<ApprovalResponse, Never>) in
            pending[request.id] = Pending(request: request, continuation: c, dedupKey: key)
            Task { await self.scheduleTimeout(id: request.id) }
        }
    }

    public func resolve(id: String, with response: ApprovalResponse) {
        guard let p = pending.removeValue(forKey: id) else { return }
        recentDecisions[p.dedupKey] = (response, Date())
        p.continuation.resume(returning: response)
        let dupIds = pending.filter { $0.value.dedupKey == p.dedupKey }.map(\.key)
        for otherId in dupIds {
            if let other = pending.removeValue(forKey: otherId) {
                other.continuation.resume(returning: response)
            }
        }
    }

    public func cancel(id: String, decision: ApprovalDecision = .deny, reason: String? = nil) {
        resolve(id: id, with: ApprovalResponse(decision: decision, reason: reason))
    }

    private func scheduleTimeout(id: String) async {
        try? await Task.sleep(for: timeout)
        if let p = pending.removeValue(forKey: id) {
            p.continuation.resume(returning: ApprovalResponse(decision: .expired))
        }
    }

    private func seconds(_ d: Duration) -> TimeInterval {
        let comps = d.components
        return TimeInterval(comps.seconds) + TimeInterval(comps.attoseconds) / 1e18
    }
}
