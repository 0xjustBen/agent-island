import Foundation

public actor HistoryWriter: HistoryRecording {
    private let url: URL
    private let rotateAtBytes: Int
    private var handle: FileHandle?

    public init(url: URL, rotateAtBytes: Int = 100 * 1024 * 1024) {
        self.url = url
        self.rotateAtBytes = rotateAtBytes
    }

    public func record(event: EventName, request: PermissionRequest,
                       decision: ApprovalResponse, latencyMs: Int) async {
        let rec: [String: Any] = [
            "ts": ISO8601DateFormatter().string(from: Date()),
            "event": event.rawValue,
            "id": request.id,
            "source": request.source,
            "dedup_key": request.dedupKey,
            "decision": decision.decision.rawValue,
            "reason": decision.reason ?? NSNull(),
            "latency_ms": latencyMs,
            "cwd": request.locator.cwd ?? NSNull(),
            "tty": request.locator.tty ?? NSNull()
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: rec,
                                                     options: [.sortedKeys]) else { return }
        write(data + Data([0x0A]))
        rotateIfNeeded()
    }

    public func flush() {
        try? handle?.synchronize()
    }

    private func ensureHandle() throws -> FileHandle {
        if let h = handle { return h }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        let h = try FileHandle(forWritingTo: url)
        try h.seekToEnd()
        handle = h
        return h
    }

    private func write(_ data: Data) {
        guard let h = try? ensureHandle() else { return }
        try? h.write(contentsOf: data)
    }

    private func rotateIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int,
              size >= rotateAtBytes else { return }
        try? handle?.close()
        handle = nil
        let rotated = url.appendingPathExtension("1")
        try? FileManager.default.removeItem(at: rotated)
        try? FileManager.default.moveItem(at: url, to: rotated)
    }
}
