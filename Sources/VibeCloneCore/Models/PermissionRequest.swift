import Foundation

public struct PermissionRequest: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let source: String              // "claude", "codex", ...
    public let payload: [String: JSONValue]
    public let locator: TerminalLocator
    public let receivedAt: Date

    public init(id: String, source: String, payload: [String: JSONValue],
                locator: TerminalLocator, receivedAt: Date) {
        self.id = id; self.source = source; self.payload = payload
        self.locator = locator; self.receivedAt = receivedAt
    }

    /// Stable hash of (source, tool/event, payload) for dedup in ApprovalQueue.
    public var dedupKey: String {
        let payloadData = (try? JSONEncoder().encode(payload)) ?? Data()
        return "\(source)|\(payloadData.fnv1a64Hex)"
    }
}

extension Data {
    /// 16-char FNV-1a 64-bit hex prefix — enough for in-window dedup, no crypto.
    var fnv1a64Hex: String {
        var hash: UInt64 = 1469598103934665603
        for b in self { hash = (hash ^ UInt64(b)) &* 1099511628211 }
        return String(hash, radix: 16)
    }
}
