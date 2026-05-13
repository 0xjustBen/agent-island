import Foundation
import CryptoKit
import AgentIslandCore

/// HMAC-SHA256 verification for frames coming in from remote bridges.
/// Remote bridges signed `_remote_sig = hex(HMAC-SHA256(key, canonical_json))`
/// where canonical_json is the payload object MINUS the `_remote_sig` key.
enum RemoteAuth {
    static func verify(payload: [String: JSONValue], key: String) -> Bool {
        guard case .string(let sigHex) = payload["_remote_sig"] ?? .null,
              let expected = Data(hexString: sigHex) else { return false }
        var copy = payload
        copy.removeValue(forKey: "_remote_sig")
        guard let body = serializeCanonical(copy) else { return false }
        let mac = HMAC<SHA256>.authenticationCode(for: body,
                                                  using: SymmetricKey(data: Data(key.utf8)))
        return Data(mac).constantTimeEquals(expected)
    }

    private static func serializeCanonical(_ payload: [String: JSONValue]) -> Data? {
        let foundationDict = JSONValueWire.unwrap(.object(payload))
        return try? JSONSerialization.data(withJSONObject: foundationDict,
                                           options: [.sortedKeys])
    }
}

private extension Data {
    init?(hexString: String) {
        let chars = Array(hexString)
        guard chars.count % 2 == 0 else { return nil }
        var out = Data(capacity: chars.count / 2)
        for i in stride(from: 0, to: chars.count, by: 2) {
            guard let b = UInt8(String(chars[i..<i+2]), radix: 16) else { return nil }
            out.append(b)
        }
        self = out
    }

    func constantTimeEquals(_ other: Data) -> Bool {
        guard self.count == other.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<self.count { diff |= self[i] ^ other[i] }
        return diff == 0
    }
}
