import Foundation
import NIO
import NIOSSH

public class SimpleSSHClient {
	private let channel: Channel
	private let sshHandler: NIOSSHHandler

	private init(channel: Channel, sshHandler: NIOSSHHandler) {
		self.channel = channel
		self.sshHandler = sshHandler
	}

	public static func connect(host: String, port: Int = 22, timeout: UInt = 30, authentication: Authentication)
		async throws -> SimpleSSHClient
	{
		let configuration = SSHClientConfiguration(
			userAuthDelegate: authentication, serverAuthDelegate: AcceptingAllHostValidator())
		let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		let bootstrap = ClientBootstrap(group: eventLoopGroup)
			.channelInitializer { channel in
				channel.pipeline.addHandler(
					NIOSSHHandler(
						role: .client(configuration),
						allocator: channel.allocator,
						inboundChildChannelInitializer: nil
					)
				)
			}
			.connectTimeout(.seconds(Int64(timeout)))
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)

		return try await bootstrap.connect(host: host, port: port)
			.flatMap { channel in
				channel.pipeline.handler(type: NIOSSHHandler.self)
					.map { sshHandler in
						SimpleSSHClient(channel: channel, sshHandler: sshHandler)
					}
			}
			.get()
	}

	public func execute(command: String, timeout: UInt = 10) async throws -> AsyncThrowingStream<CommandOutput, Error> {
		var streamContinuation: AsyncThrowingStream<CommandOutput, Error>.Continuation!
		let stream = AsyncThrowingStream<CommandOutput, Error> { continuation in
			streamContinuation = continuation
		}

		let commandHandler = CommandExecutionHandler(eventHandler: streamContinuation.fromCommandHandlerEvent)
		let executionChannel = channel.eventLoop.makePromise(of: Channel.self)
		sshHandler.createChannel(executionChannel) { channel, _ in
			channel.pipeline.addHandler(commandHandler)
		}
		channel.eventLoop.scheduleTask(in: .seconds(Int64(timeout))) {
			executionChannel.fail(ChannelFailure("Command execution timed out."))
		}
		let channel = try await channel.eventLoop
			.flatSubmit {
				executionChannel.futureResult
			}
			.get()
		try await channel.triggerUserOutboundEvent(
			SSHChannelRequestEvent.ExecRequest(command: command, wantReply: true))
		return stream
	}
}
