import Foundation

/// A notification or ask-style message from an agent. Surfaced in UI until
/// the user dismisses or it ages out.
public struct Notice: Identifiable, Hashable, Sendable {
    public let id: String
    public let source: String
    public let message: String
    public let locator: TerminalLocator
    public let receivedAt: Date

    public init(id: String, source: String, message: String,
                locator: TerminalLocator, receivedAt: Date) {
        self.id = id; self.source = source; self.message = message
        self.locator = locator; self.receivedAt = receivedAt
    }
}

public actor NoticeStore {
    private var notices: [Notice] = []
    private let maxAge: TimeInterval

    public init(maxAge: TimeInterval = 5 * 60) {
        self.maxAge = maxAge
    }

    public func add(_ n: Notice) {
        pruneExpired()
        // Dedup by (source, message) within window.
        if !notices.contains(where: { $0.source == n.source && $0.message == n.message }) {
            notices.append(n)
        }
    }

    public func dismiss(id: String) {
        notices.removeAll { $0.id == id }
    }

    public func snapshot() -> [Notice] {
        pruneExpired()
        return notices
    }

    public var count: Int {
        pruneExpired()
        return notices.count
    }

    private func pruneExpired() {
        let cutoff = Date().addingTimeInterval(-maxAge)
        notices.removeAll { $0.receivedAt < cutoff }
    }
}
