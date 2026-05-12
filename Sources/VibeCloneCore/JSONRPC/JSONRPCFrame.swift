import Foundation

public enum JSONRPCFrame: Sendable {
    case request(id: String, method: String, params: [String: JSONValue])
    case response(id: String, result: [String: JSONValue]?, error: JSONRPCErrorPayload?)
    case notification(method: String, params: [String: JSONValue])
}

public struct JSONRPCErrorPayload: Codable, Hashable, Sendable {
    public let code: Int
    public let message: String
    public init(code: Int, message: String) {
        self.code = code; self.message = message
    }
}

public enum JSONRPCError: Error, Equatable {
    case oversizeFrame(Int)
    case malformed(String)
}
