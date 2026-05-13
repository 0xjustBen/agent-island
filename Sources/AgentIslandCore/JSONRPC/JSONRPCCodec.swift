import Foundation

public enum JSONRPCCodec {
    public static let maxFrameSize = 1 << 20   // 1 MiB

    /// Encode a frame to length-prefixed bytes.
    public static func encode(_ frame: JSONRPCFrame) throws -> [UInt8] {
        let dict = wireDict(for: frame)
        let body = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
        guard body.count <= maxFrameSize else { throw JSONRPCError.oversizeFrame(body.count) }
        var out = [UInt8](repeating: 0, count: 4)
        let len = UInt32(body.count).bigEndian
        withUnsafeBytes(of: len) { out.replaceSubrange(0..<4, with: $0) }
        out.append(contentsOf: body)
        return out
    }

    /// Throws if frame malformed or short. Otherwise decodes one frame from front of buffer.
    public static func decode(_ buf: inout [UInt8]) throws -> JSONRPCFrame {
        guard let result = try tryDecode(&buf) else { throw JSONRPCError.malformed("short read") }
        return result
    }

    /// Returns nil and leaves buffer untouched when not enough bytes yet. Throws on oversize.
    public static func tryDecode(_ buf: inout [UInt8]) throws -> JSONRPCFrame? {
        guard buf.count >= 4 else { return nil }
        let len = (UInt32(buf[0]) << 24) | (UInt32(buf[1]) << 16) | (UInt32(buf[2]) << 8) | UInt32(buf[3])
        guard Int(len) <= maxFrameSize else { throw JSONRPCError.oversizeFrame(Int(len)) }
        guard buf.count >= 4 + Int(len) else { return nil }
        let body = Data(buf[4..<(4 + Int(len))])
        buf.removeFirst(4 + Int(len))
        guard let obj = try JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            throw JSONRPCError.malformed("not an object")
        }
        return try parse(obj)
    }

    private static func wireDict(for frame: JSONRPCFrame) -> [String: Any] {
        switch frame {
        case .request(let id, let method, let params):
            return ["jsonrpc": "2.0", "id": id, "method": method,
                    "params": JSONValueWire.unwrap(.object(params))]
        case .response(let id, let result, let error):
            var d: [String: Any] = ["jsonrpc": "2.0", "id": id]
            if let r = result { d["result"] = JSONValueWire.unwrap(.object(r)) }
            if let e = error  { d["error"] = ["code": e.code, "message": e.message] }
            return d
        case .notification(let method, let params):
            return ["jsonrpc": "2.0", "method": method,
                    "params": JSONValueWire.unwrap(.object(params))]
        }
    }

    private static func parse(_ obj: [String: Any]) throws -> JSONRPCFrame {
        let method = obj["method"] as? String
        let id = (obj["id"] as? String) ?? (obj["id"] as? Int).map(String.init)
        let params = (obj["params"] as? [String: Any]).flatMap { JSONValueWire.wrapObject($0) } ?? [:]
        if let id, let method { return .request(id: id, method: method, params: params) }
        if let method         { return .notification(method: method, params: params) }
        guard let id else { throw JSONRPCError.malformed("missing id and method") }
        let resultDict = (obj["result"] as? [String: Any]).flatMap { JSONValueWire.wrapObject($0) }
        let errDict = obj["error"] as? [String: Any]
        let err = errDict.flatMap { d -> JSONRPCErrorPayload? in
            guard let c = d["code"] as? Int, let m = d["message"] as? String else { return nil }
            return JSONRPCErrorPayload(code: c, message: m)
        }
        return .response(id: id, result: resultDict, error: err)
    }
}
