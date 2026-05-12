import Testing
import Foundation
@testable import VibeCloneCore

@Test func encode_then_decode_roundTrips() throws {
    let req = JSONRPCFrame.request(id: "1", method: "event.PermissionRequest",
                                   params: ["tool": .string("Bash")])
    let bytes = try JSONRPCCodec.encode(req)
    #expect(bytes.count > 4)
    let len = UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3])
    #expect(Int(len) == bytes.count - 4)
    var buf = bytes
    let decoded = try JSONRPCCodec.decode(&buf)
    if case .request(let id, let method, _) = decoded {
        #expect(id == "1")
        #expect(method == "event.PermissionRequest")
    } else { Issue.record("wrong frame case") }
    #expect(buf.isEmpty)
}

@Test func encode_response_then_decode() throws {
    let resp = JSONRPCFrame.response(id: "abc", result: ["decision": .string("allow")], error: nil)
    let bytes = try JSONRPCCodec.encode(resp)
    var buf = bytes
    let decoded = try JSONRPCCodec.decode(&buf)
    if case .response(let id, let result, let err) = decoded {
        #expect(id == "abc")
        #expect(err == nil)
        if case .string(let s) = result?["decision"] ?? .null { #expect(s == "allow") }
        else { Issue.record("decision missing") }
    } else { Issue.record("wrong frame case") }
}

@Test func decode_rejects_oversize_frame() {
    var buf: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF]   // claims 4 GiB
    #expect(throws: JSONRPCError.self) { try JSONRPCCodec.decode(&buf) }
}

@Test func tryDecode_returns_nil_on_partial_frame() throws {
    var buf: [UInt8] = [0, 0, 0, 10, 0x7B]    // claims 10 bytes, only 1 present
    let result = try JSONRPCCodec.tryDecode(&buf)
    #expect(result == nil)
    #expect(buf.count == 5)
}

@Test func tryDecode_returns_nil_when_under_4_bytes() throws {
    var buf: [UInt8] = [0, 0, 0]
    let result = try JSONRPCCodec.tryDecode(&buf)
    #expect(result == nil)
    #expect(buf.count == 3)
}
