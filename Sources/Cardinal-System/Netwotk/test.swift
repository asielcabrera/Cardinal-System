//
//  File.swift
//
//
//  Created by Asiel Cabrera Gonzalez on 1/6/24.
//

import NIO
import NIOHTTP1
import NIOWebSocket
import Foundation

let websocketResponse = """
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Swift NIO WebSocket Test Page</title>
    <script>
        var wsconnection = new WebSocket("ws://localhost:8888/websocket");
        wsconnection.onmessage = function (msg) {
            var eventData = JSON.parse(msg.data);
            logEventOrAction(eventData);
        };

        function sendAction(actionName) {
            wsconnection.send(JSON.stringify({ type: 'action', name: actionName }));
        }

        function logEventOrAction(data) {
            var logElement = document.getElementById("log");
            var logEntry = document.createElement("p");
            logEntry.innerHTML = `Event: ${data.event}, Time: ${data.time}, ID: ${data.id}`;
            logElement.insertBefore(logEntry, null);
        }
    </script>
  </head>
  <body>
    <h1>WebSocket Stream</h1>
    <button onclick="sendAction('yourActionName')">Send Action</button>
    <h2>Log</h2>
    <div id="log"></div>
  </body>
</html>
"""




private final class HTTPHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private var responseBody: ByteBuffer!
    
    func handlerAdded(context: ChannelHandlerContext) {
        self.responseBody = context.channel.allocator.buffer(string: websocketResponse)
    }
    
    func handlerRemoved(context: ChannelHandlerContext) {
        self.responseBody = nil
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        // We're not interested in request bodies here: we're just serving up GET responses
        // to get the client to initiate a websocket request.
        guard case .head(let head) = reqPart else {
            return
        }
        
        // GETs only.
        guard case .GET = head.method else {
            self.respond405(context: context)
            return
        }
        
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "text/html")
        headers.add(name: "Content-Length", value: String(self.responseBody.readableBytes))
        headers.add(name: "Connection", value: "close")
        let responseHead = HTTPResponseHead(version: .http1_1, status: .ok, headers: headers)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(self.responseBody))), promise: nil)
        context.write(self.wrapOutboundOut(.end(nil))).whenComplete { (_: Result<Void, Error>) in
            context.close(promise: nil)
        }
        context.flush()
    }
    
    private func respond405(context: ChannelHandlerContext) {
        var headers = HTTPHeaders()
        headers.add(name: "Connection", value: "close")
        headers.add(name: "Content-Length", value: "0")
        let head = HTTPResponseHead(version: .http1_1, status: .methodNotAllowed, headers: headers)
        context.write(self.wrapOutboundOut(.head(head)), promise: nil)
        context.write(self.wrapOutboundOut(.end(nil))).whenComplete { (_: Result<Void, Error>) in
            context.close(promise: nil)
        }
        context.flush()
    }
}

private final class WebSocketTimeHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame
    
    private var awaitingClose: Bool = false
    
    public func handlerAdded(context: ChannelHandlerContext) {
//        self.sendTime(context: context)
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)
        
        switch frame.opcode {
        case .connectionClose:
            self.receivedClose(context: context, frame: frame)
        case .ping:
            self.pong(context: context, frame: frame)
        case .text:
            var data = frame.unmaskedData
            let text = data.readString(length: data.readableBytes) ?? ""
            print(text)
        case .binary, .continuation, .pong:
            // We ignore these frames.
            break
        default:
            // Unknown frames are errors.
            self.closeOnError(context: context)
        }
    }
    
    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
    
    private func sendTime(context: ChannelHandlerContext) {
        guard context.channel.isActive else { return }
        
        // We can't send if we sent a close message.
        guard !self.awaitingClose else { return }
        
        // We can't really check for error here, but it's also not the purpose of the
        // example so let's not worry about it.
        let theTime = NIODeadline.now().uptimeNanoseconds
        var buffer = context.channel.allocator.buffer(capacity: 12)
        buffer.writeString("\(theTime)")
        
        let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
        context.writeAndFlush(self.wrapOutboundOut(frame)).map {
            context.eventLoop.scheduleTask(in: .seconds(1), { self.sendTime(context: context) })
        }.whenFailure { (_: Error) in
            context.close(promise: nil)
        }
    }
    
    private func receivedClose(context: ChannelHandlerContext, frame: WebSocketFrame) {
        // Handle a received close frame. In websockets, we're just going to send the close
        // frame and then close, unless we already sent our own close frame.
        if awaitingClose {
            // Cool, we started the close and were waiting for the user. We're done.
            context.close(promise: nil)
        } else {
            // This is an unsolicited close. We're going to send a response frame and
            // then, when we've sent it, close up shop. We should send back the close code the remote
            // peer sent us, unless they didn't send one at all.
            var data = frame.unmaskedData
            let closeDataCode = data.readSlice(length: 2) ?? ByteBuffer()
            let closeFrame = WebSocketFrame(fin: true, opcode: .connectionClose, data: closeDataCode)
            _ = context.write(self.wrapOutboundOut(closeFrame)).map { () in
                context.close(promise: nil)
            }
        }
    }
    
    private func pong(context: ChannelHandlerContext, frame: WebSocketFrame) {
        var frameData = frame.data
        let maskingKey = frame.maskKey
        
        if let maskingKey = maskingKey {
            frameData.webSocketUnmask(maskingKey)
        }
        
        let responseFrame = WebSocketFrame(fin: true, opcode: .pong, data: frameData)
        context.write(self.wrapOutboundOut(responseFrame), promise: nil)
    }
    
    private func closeOnError(context: ChannelHandlerContext) {
        // We have hit an error, we want to close. We do that by sending a close frame and then
        // shutting down the write side of the connection.
        var data = context.channel.allocator.buffer(capacity: 2)
        data.write(webSocketErrorCode: .protocolError)
        let frame = WebSocketFrame(fin: true, opcode: .connectionClose, data: data)
        context.write(self.wrapOutboundOut(frame)).whenComplete { (_: Result<Void, Error>) in
            context.close(mode: .output, promise: nil)
        }
        awaitingClose = true
    }
}

public struct AllWebSockets {
    public static var sockets: [WebSocket] = []
 }

public struct WebSocket {
    var channel: Channel
}

public extension WebSocket {
    func sendText(_ text: String) {
            var buffer = channel.allocator.buffer(capacity: text.utf8.count)
            buffer.writeString(text)
            
            let textFrame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
            _ = channel.writeAndFlush(textFrame)
        }
}

private final class WebSocketHandler: ChannelInboundHandler {
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    private var awaitingClose: Bool = false

    func handlerAdded(context: ChannelHandlerContext) {
        AllWebSockets.sockets.append(WebSocket(channel: context.channel))
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        // Remove the WebSocket from the global list when the handler is removed.
        AllWebSockets.sockets.removeAll { $0.channel === context.channel }
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)

        switch frame.opcode {
        case .connectionClose:
            self.receivedClose(context: context, frame: frame)
        case .ping:
            self.pong(context: context, frame: frame)
        case .text:
            self.handleTextFrame(context: context, frame: frame)
        case .binary, .continuation, .pong:
            // We ignore these frames.
            break
        default:
            // Unknown frames are errors.
            self.closeOnError(context: context)
        }
    }

    private func receivedClose(context: ChannelHandlerContext, frame: WebSocketFrame) {
        // Handle a received close frame. In websockets, we're just going to send the close
        // frame and then close, unless we already sent our own close frame.
        if awaitingClose {
            // Cool, we started the close and were waiting for the user. We're done.
            context.close(promise: nil)
        } else {
            // This is an unsolicited close. We're going to send a response frame and
            // then, when we've sent it, close up shop. We should send back the close code the remote
            // peer sent us, unless they didn't send one at all.
            var data = frame.unmaskedData
            let closeDataCode = data.readSlice(length: 2) ?? ByteBuffer()
            let closeFrame = WebSocketFrame(fin: true, opcode: .connectionClose, data: closeDataCode)
            _ = context.write(self.wrapOutboundOut(closeFrame)).map { () in
                context.close(promise: nil)
            }
        }
    }

    private func pong(context: ChannelHandlerContext, frame: WebSocketFrame) {
        var frameData = frame.data
        let maskingKey = frame.maskKey

        if let maskingKey = maskingKey {
            frameData.webSocketUnmask(maskingKey)
        }

        let responseFrame = WebSocketFrame(fin: true, opcode: .pong, data: frameData)
        context.write(self.wrapOutboundOut(responseFrame), promise: nil)
    }

    private func closeOnError(context: ChannelHandlerContext) {
        // We have hit an error, we want to close. We do that by sending a close frame and then
        // shutting down the write side of the connection.
        var data = context.channel.allocator.buffer(capacity: 2)
        data.write(webSocketErrorCode: .protocolError)
        let frame = WebSocketFrame(fin: true, opcode: .connectionClose, data: data)
        context.write(self.wrapOutboundOut(frame)).whenComplete { (_: Result<Void, Error>) in
            context.close(mode: .output, promise: nil)
        }
        awaitingClose = true
    }

    private func handleTextFrame(context: ChannelHandlerContext, frame: WebSocketFrame) {
        var data = frame.unmaskedData
        let text = data.readString(length: data.readableBytes) ?? ""
        
        // Aquí puedes procesar el texto como un JSON y manejar eventos y acciones.
        // Por ejemplo, puedes decodificar el JSON y buscar el nombre de un evento o acción.

        print("Received text frame: \(text)")

        // Ejemplo de procesamiento de un JSON simulado
        
        if let data = text.data(using: .utf8) {
            let decoder = JSONDecoder()
            let dataDecoded = try? decoder.decode(EventData.self, from: data)
            
            let event = PrintEvent(action: { AllWebSockets.sockets.forEach { socket in
                let data = 
"""
                {
                    "id": "\(UUID.init())",
                    "event": "\(PrintEvent.self)",
                    "time": "\(Date().description)"
                }
"""
                socket.sendText(data)
            }})
            
            ActionExecutor.notifyActions(event)
            ActionExecutor.notifyActions(event)
            print(dataDecoded)
        }
        
        
//        if let jsonData = text.data(using: .utf8),
//           let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
//            if let eventType = json["eventType"] as? String {
//                // Aquí puedes buscar el evento y notificar a los observadores.
//                let event = YourEventType(name: eventType)
//                EventManager.shared.notifyObservers(event)
//            }
//            
//            if let actionName = json["actionName"] as? String {
//                // Aquí puedes buscar la acción y ejecutarla.
//                let action = YourActionType(name: actionName)
//                ActionExecutor.shared.execute(action)
//            }
//        }
    }
}

struct PrintAction: CardinalAction {
    var eventAssociated: Event.Type = PrintEvent.self
    
    func execute(_ event: Event) {
        event.action()
    }
}

class PrintEvent: Event {
    var id: UUID
    
    var name: String = "PrintEvent"
    
    var description: String = "Evento para pruebas de hacer print en consola"
    
    
    
    
    var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.id = .init()
        self.action = action
    }
    
}

struct EventData: Codable {
    let type: String
    let name: String
}

struct WebSocketServer {
    private var group: MultiThreadedEventLoopGroup
    private var bootstrap: ServerBootstrap
    private var channel: Channel?
    
    init() throws {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let upgrader = NIOWebSocketServerUpgrader(shouldUpgrade: { (channel: Channel, head: HTTPRequestHead) in channel.eventLoop.makeSucceededFuture(HTTPHeaders()) },
                                                  upgradePipelineHandler: { (channel: Channel, _: HTTPRequestHead) in
            channel.pipeline.addHandler(WebSocketHandler())
        })
        ActionExecutor.registerAction(PrintAction())
        self.bootstrap = ServerBootstrap(group: group)
        // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        
        // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { channel in
                let httpHandler = HTTPHandler()
                let config: NIOHTTPServerUpgradeConfiguration = (
                    upgraders: [upgrader],
                    completionHandler: { _ in
                        channel.pipeline.removeHandler(httpHandler, promise: nil)
                    }
                )
                return channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: config).flatMap {
                    channel.pipeline.addHandler(httpHandler)
                }
            }
        
        // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
    }
    
    mutating func start() throws {
        self.channel = try self.bootstrap.bind(host: "localhost", port: 8888).wait()
        guard let localAddress = self.channel?.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        print("Server started and listening on \(localAddress)")
    }
    
    func waitForShutdown() throws {
        try self.channel?.closeFuture.wait()
    }
    
    func stop() throws {
        try self.group.syncShutdownGracefully()
    }
}

//
//struct ALO: Cardinal {
//    struct App: Application {
//        var name: String
//    }
//
//    static var application: App = App(name: "ALO")
//
//    static func run() async throws {
//        let server = try await Server(
//            host: "localhost",
//            port: 8888,
//            eventLoopGroup: .singleton
//        )
//        try await server.run()
//    }
//}
//
//protocol Application {
//    var host: String { get }
//    var port: Int { get }
//    var eventLoopGroup: MultiThreadedEventLoopGroup { get }
//
//    init(host: String, port: Int, eventLoopGroup: MultiThreadedEventLoopGroup) throws
//
//    func run() async throws
//}
//
//extension Application {
//    func handleUpgradeResult(_ upgradeResult: EventLoopFuture<UpgradeResult>) async throws {
//        // Tu implementación actual de handleUpgradeResult
//    }
//
//    func handleWebsocketChannel(_ channel: NIOAsyncChannel<WebSocketFrame, WebSocketFrame>) async throws {
//        // Tu implementación actual de handleWebsocketChannel
//    }
//
//    func handleHTTPChannel(_ channel: NIOAsyncChannel<HTTPServerRequestPart, HTTPPart<HTTPResponseHead, ByteBuffer>>) async throws {
//        // Tu implementación actual de handleHTTPChannel
//    }
//
//    func respond405(writer: NIOAsyncChannelOutboundWriter<HTTPPart<HTTPResponseHead, ByteBuffer>>) async throws {
//        // Tu implementación actual de respond405
//    }
//}
//
//extension Application {
//    func run() async throws {
//        let channel: NIOAsyncChannel<EventLoopFuture<UpgradeResult>, Never> = try await ServerBootstrap(group: self.eventLoopGroup)
//            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
//            .bind(
//                host: self.host,
//                port: self.port
//            ) { channel in
//                channel.eventLoop.makeCompletedFuture {
//                    // ... (como en tu código original)
//                }
//            }
//
//        try await withThrowingDiscardingTaskGroup { group in
//            try await channel.executeThenClose { inbound in
//                for try await upgradeResult in inbound {
//                    group.addTask {
//                        await self.handleUpgradeResult(upgradeResult)
//                    }
//                }
//            }
//        }
//    }
//}
//
//#else
//@main
//struct Server {
//    static func main() {
//        fatalError("Requires at least Swift 5.9")
//    }
//}
//#endif
