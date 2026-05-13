import Foundation

public enum JSONValue: Codable, Hashable, Sendable {
    case string(String), number(Double), bool(Bool), null
    case array([JSONValue]), object([String: JSONValue])

    public init(from d: Decoder) throws {
        let c = try d.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let v = try? c.decode(Bool.self)             { self = .bool(v); return }
        if let v = try? c.decode(Double.self)           { self = .number(v); return }
        if let v = try? c.decode(String.self)           { self = .string(v); return }
        if let v = try? c.decode([JSONValue].self)      { self = .array(v); return }
        if let v = try? c.decode([String: JSONValue].self) { self = .object(v); return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "bad json")
    }
    public func encode(to e: Encoder) throws {
        var c = e.singleValueContainer()
        switch self {
        case .null:          try c.encodeNil()
        case .bool(let v):   try c.encode(v)
        case .number(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .array(let v):  try c.encode(v)
        case .object(let v): try c.encode(v)
        }
    }
}

/// Helpers used by Task 4 (JSON-RPC codec) and Task 7 (adapter) to bridge
/// JSONSerialization's `Any` graph and JSONValue.
public enum JSONValueWire {
    public static func wrap(_ any: Any) -> JSONValue {
        if any is NSNull { return .null }
        if let b = any as? Bool   { return .bool(b) }
        if let n = any as? Double { return .number(n) }
        if let n = any as? Int    { return .number(Double(n)) }
        if let s = any as? String { return .string(s) }
        if let a = any as? [Any]  { return .array(a.map(wrap)) }
        if let o = any as? [String: Any] { return .object(wrapObject(o)) }
        return .null
    }
    public static func wrapObject(_ o: [String: Any]) -> [String: JSONValue] {
        var out: [String: JSONValue] = [:]; for (k, v) in o { out[k] = wrap(v) }; return out
    }
    public static func unwrap(_ v: JSONValue) -> Any {
        switch v {
        case .null:          return NSNull()
        case .bool(let b):   return b
        case .number(let n): return n
        case .string(let s): return s
        case .array(let a):  return a.map(unwrap)
        case .object(let o):
            var d: [String: Any] = [:]; for (k, v) in o { d[k] = unwrap(v) }; return d
        }
    }
}
