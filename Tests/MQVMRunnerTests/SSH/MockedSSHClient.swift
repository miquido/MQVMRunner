import Foundation
import NIO
import SimpleSSHClient

@testable import MQVMRunner

final class MockedSSHClient: SSHClientProtocol {
	var executedCommand: String? = nil

	func execute(command: String, timeout: UInt = 30) async throws -> AsyncThrowingStream<CommandOutput, Error> {
		executedCommand = command
		return AsyncThrowingStream { continuation in
			continuation.yield(CommandOutput.standardOutput(ByteBuffer()))
			continuation.finish()
		}
	}
}
