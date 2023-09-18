import Foundation
import NIO
import NIOSSH

final class CommandExecutionHandler: ChannelDuplexHandler {
	typealias InboundIn = SSHChannelData
	typealias OutboundIn = ByteBuffer

	private let eventHandler: (Event) -> Void
	/// The exit status of the command. It is possible that we receive the exit status before we receive all the output.
	/// Therefore, we need to store it and yield it when the channel becomes inactive.
	private var exitStatus: Int?

	init(eventHandler: @escaping (Event) -> Void) {
		self.eventHandler = eventHandler
	}

	func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
		switch event {
		case is ChannelFailureEvent:
			eventHandler(.failure(ChannelFailure("Channel failed.")))
		case is SSHChannelRequestEvent.ExitStatus:
			guard let exitStatus = (event as? SSHChannelRequestEvent.ExitStatus)?.exitStatus else {
				eventHandler(.failure(ChannelFailure("Unexpected event type.")))
				return
			}
			self.exitStatus = exitStatus
		default:
			context.fireUserInboundEventTriggered(event)
		}
	}

	func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let data = unwrapInboundIn(data)
		guard case .byteBuffer(let buffer) = data.data else {
			eventHandler(.failure(ChannelFailure("Invalid data type.")))
			return
		}
		if data.type == .channel {
			eventHandler(.output(buffer))
		} else {
			eventHandler(.error(buffer))
		}
	}

	func errorCaught(context: ChannelHandlerContext, error: Error) {
		eventHandler(.failure(error))
	}

	func channelInactive(context: ChannelHandlerContext) {
		eventHandler(.completed(exitStatus ?? 0))
	}
}

extension CommandExecutionHandler {
	enum Event {
		case output(ByteBuffer)
		case error(ByteBuffer)
		case completed(Int)
		case failure(Error)
	}
}
