import Foundation
import Darwin
import VibeCloneCore
import VibeCloneAdapters

@main
struct VibeCloneBridge {
    static func main() {
        let args = ProcessInfo.processInfo.arguments
        guard let srcIdx = args.firstIndex(of: "--source"), srcIdx + 1 < args.count else {
            // Always non-blocking. Empty stdout, exit 0.
            FileHandle.standardOutput.write(Data("{}".utf8)); exit(0)
        }
        let source = args[srcIdx + 1]

        let stdinData = FileHandle.standardInput.readDataToEndOfFile()
        let paths = Paths()
        let locator = currentLocator()
        let requestId = UUID().uuidString

        let adapter: AgentAdapter
        switch source {
        case "claude": adapter = ClaudeCodeAdapter()
        default:
            FileHandle.standardOutput.write(Data("{}".utf8)); exit(0)
        }

        do {
            let (event, payload) = try adapter.decodeStdin(stdinData)
            let request = PermissionRequest(
                id: requestId, source: source, payload: payload,
                locator: locator, receivedAt: Date()
            )
            let timeoutSec = event.timeoutSeconds ?? 30
            let body = try exchange(paths: paths, event: event, request: request,
                                    timeoutSeconds: timeoutSec)
            FileHandle.standardOutput.write(body)
            exit(0)
        } catch {
            // Non-blocking fail.
            FileHandle.standardOutput.write(Data("{}".utf8))
            try? "\(Date()) bridge error: \(error)\n".data(using: .utf8)?
                .append(to: paths.diagnosticLog)
            exit(0)
        }
    }

    static func exchange(paths: Paths, event: EventName,
                         request: PermissionRequest, timeoutSeconds: Int) throws -> Data {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw BridgeError.socket(errno) }
        defer { close(fd) }

        var connectTV = timeval(tv_sec: 2, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &connectTV,
                   socklen_t(MemoryLayout<timeval>.size))
        var readTV = timeval(tv_sec: Int(timeoutSeconds), tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &readTV,
                   socklen_t(MemoryLayout<timeval>.size))

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        _ = paths.socket.path.withCString { src in
            withUnsafeMutablePointer(to: &addr.sun_path) { dst in
                dst.withMemoryRebound(to: CChar.self, capacity: 104) { p in
                    _ = strncpy(p, src, 103)
                }
            }
        }
        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        let r = withUnsafePointer(to: &addr) { p in
            p.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                Darwin.connect(fd, sa, addrLen)
            }
        }
        guard r == 0 else { throw BridgeError.connect(errno) }

        let method = "event.\(event.rawValue)"
        let params: [String: JSONValue] = [
            "source":  .string(request.source),
            "payload": .object(request.payload),
            "locator": .object([
                "tty":  request.locator.tty.map(JSONValue.string) ?? .null,
                "cwd":  request.locator.cwd.map(JSONValue.string) ?? .null,
                "ppid": request.locator.ppid.map { .number(Double($0)) } ?? .null
            ])
        ]
        let frame = JSONRPCFrame.request(id: request.id, method: method, params: params)
        let bytes = try JSONRPCCodec.encode(frame)
        try writeAll(fd: fd, bytes: bytes)

        var buf = [UInt8]()
        var chunk = [UInt8](repeating: 0, count: 4096)
        while true {
            let n = chunk.withUnsafeMutableBufferPointer { Darwin.read(fd, $0.baseAddress, $0.count) }
            if n <= 0 { throw BridgeError.readClosed }
            buf.append(contentsOf: chunk.prefix(n))
            while let f = try JSONRPCCodec.tryDecode(&buf) {
                if case .response(let id, let result, _) = f, id == request.id {
                    // result is the adapter's already-encoded stdout body as a JSON object.
                    let dict = JSONValueWire.unwrap(.object(result ?? [:]))
                    return try JSONSerialization.data(withJSONObject: dict,
                                                      options: [.sortedKeys])
                }
            }
        }
    }

    static func currentLocator() -> TerminalLocator {
        var ttyBuf = [CChar](repeating: 0, count: 128)
        let tty: String? = ttyname_r(0, &ttyBuf, ttyBuf.count) == 0
            ? String(cString: ttyBuf) : nil
        return TerminalLocator(
            tty: tty,
            cwd: FileManager.default.currentDirectoryPath,
            ppid: getppid()
        )
    }

    static func writeAll(fd: Int32, bytes: [UInt8]) throws {
        var rem = bytes[...]
        while !rem.isEmpty {
            let n = rem.withUnsafeBufferPointer { Darwin.write(fd, $0.baseAddress, $0.count) }
            if n <= 0 { throw BridgeError.write(errno) }
            rem = rem.dropFirst(n)
        }
    }
}

enum BridgeError: Error { case socket(Int32), connect(Int32), write(Int32), readClosed }

// Append helper for diagnostic log.
extension Data {
    func append(to url: URL) throws {
        if let h = try? FileHandle(forWritingTo: url) {
            try h.seekToEnd()
            try h.write(contentsOf: self)
            try h.close()
        } else {
            try self.write(to: url)
        }
    }
}
