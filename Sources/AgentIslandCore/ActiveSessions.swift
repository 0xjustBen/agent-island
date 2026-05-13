import Foundation

public actor ActiveSessions {
    public struct Entry: Sendable, Hashable {
        public let sessionId: String
        public let source: String
        public let locator: TerminalLocator
        public let startedAt: Date
        public var subagentDepth: Int
    }

    private var sessions: [String: Entry] = [:]
    public init() {}

    public func start(sessionId: String, source: String, locator: TerminalLocator) {
        sessions[sessionId] = Entry(sessionId: sessionId, source: source,
                                    locator: locator, startedAt: Date(),
                                    subagentDepth: 0)
    }

    public func end(sessionId: String) {
        sessions.removeValue(forKey: sessionId)
    }

    public func subagentDelta(sessionId: String, delta: Int) {
        sessions[sessionId]?.subagentDepth += delta
    }

    public func subagentDepth(sessionId: String) -> Int {
        sessions[sessionId]?.subagentDepth ?? 0
    }

    public var activeCount: Int { sessions.count }
    public var all: [Entry] { Array(sessions.values) }
}
