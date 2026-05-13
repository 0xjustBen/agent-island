import Foundation
import NIO
import NIOPosix
import AgentIslandCore
import AgentIslandAdapters

@MainActor
final class SocketServer {
    private var group: EventLoopGroup?
    private var channel: Channel?
    private let router: EventRouter
    private let paths: Paths

    init(router: EventRouter, paths: Paths) {
        self.router = router
        self.paths = paths
    }

    func start() throws {
        try paths.ensureAll()
        // Remove stale socket file if present.
        try? FileManager.default.removeItem(at: paths.socket)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.group = group
        let r = self.router
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 32)
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(FrameDecoder()).flatMap {
                    channel.pipeline.addHandler(RequestHandler(router: r))
                }
            }
        channel = try bootstrap.bind(unixDomainSocketPath: paths.socket.path).wait()
        // Restrict to owner-only.
        chmod(paths.socket.path, 0o600)
    }

    func stop() {
        try? channel?.close().wait()
        try? group?.syncShutdownGracefully()
        try? FileManager.default.removeItem(at: paths.socket)
    }
}

/// Translates inbound bytes into JSONRPCFrame events. Handles partial frames.
private final class FrameDecoder: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = JSONRPCFrame
    private var pending: [UInt8] = []

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = self.unwrapInboundIn(data)
        if let bytes = buffer.readBytes(length: buffer.readableBytes) {
            pending.append(contentsOf: bytes)
        }
        do {
            while let frame = try JSONRPCCodec.tryDecode(&pending) {
                context.fireChannelRead(self.wrapInboundOut(frame))
            }
        } catch {
            context.fireErrorCaught(error)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.close(promise: nil)
    }
}

/// Routes JSONRPCFrame requests to the EventRouter. One request per connection.
private final class RequestHandler: ChannelInboundHandler {
    typealias InboundIn = JSONRPCFrame
    let router: EventRouter

    init(router: EventRouter) { self.router = router }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)
        guard case .request(let id, let method, let params) = frame,
              method.hasPrefix("event.") else { return }
        let eventName = String(method.dropFirst("event.".count))
        guard let event = EventName(rawValue: eventName) else {
            // Unknown event — respond {} and close.
            sendEmptyResponse(channel: context.channel, id: id)
            return
        }

        let source: String = {
            if case .string(let s) = params["source"] ?? .null { return s }
            return "?"
        }()
        let payload: [String: JSONValue] = {
            if case .object(let o) = params["payload"] ?? .null { return o }
            return [:]
        }()

        // Reject unsigned remote frames when an auth key is configured.
        if payload["_remote_host"] != nil {
            if let key = ProcessInfo.processInfo.environment["AGENTISLAND_REMOTE_KEY"], !key.isEmpty {
                if !RemoteAuth.verify(payload: payload, key: key) {
                    sendEmptyResponse(channel: context.channel, id: id)
                    return
                }
            }
        }
        let locator: TerminalLocator = decodeLocator(params["locator"])

        let req = PermissionRequest(
            id: id, source: source, payload: payload,
            locator: locator, receivedAt: Date()
        )
        let r = self.router
        let channel = context.channel
        Task {
            let result = await r.route(event: event, request: req)
            let resultDict = (try? JSONSerialization.jsonObject(with: result.stdoutJSON))
                as? [String: Any] ?? [:]
            let resp = JSONRPCFrame.response(
                id: id,
                result: JSONValueWire.wrapObject(resultDict),
                error: nil
            )
            if let bytes = try? JSONRPCCodec.encode(resp) {
                var buf = channel.allocator.buffer(capacity: bytes.count)
                buf.writeBytes(bytes)
                _ = try? await channel.writeAndFlush(buf)
            }
            try? await channel.close()
        }
    }

    private func decodeLocator(_ value: JSONValue?) -> TerminalLocator {
        guard case .object(let o) = value ?? .null else {
            return TerminalLocator(tty: nil, cwd: nil, ppid: nil)
        }
        let tty: String? = { if case .string(let s) = o["tty"] ?? .null { return s }; return nil }()
        let cwd: String? = { if case .string(let s) = o["cwd"] ?? .null { return s }; return nil }()
        let ppid: Int32? = {
            if case .number(let n) = o["ppid"] ?? .null { return Int32(n) }
            return nil
        }()
        return TerminalLocator(tty: tty, cwd: cwd, ppid: ppid)
    }

    private func sendEmptyResponse(channel: Channel, id: String) {
        let resp = JSONRPCFrame.response(id: id, result: [:], error: nil)
        if let bytes = try? JSONRPCCodec.encode(resp) {
            var buf = channel.allocator.buffer(capacity: bytes.count)
            buf.writeBytes(bytes)
            _ = channel.writeAndFlush(buf)
        }
        _ = channel.close()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.close(promise: nil)
    }
}
