import Foundation
import NIO
import SimpleSSHClient

@testable import MQVMRunner

enum SSHExecutionResult {
	case `throw`(error: Error)
	case softThrow(error: Error)
	case result(result: String)
}

extension SSHExecutor {
	static func mock(
		execute: @escaping (SSHClientProtocol, String) async throws
			-> AsyncThrowingStream<CommandOutput, Error> = { _, _ in
				AsyncThrowingStream { continuation in
					continuation.finish()
				}
			}
	) -> Self {
		return Self(
			getClientUsingPassword: { _, _, _ in MockedSSHClient() },
			getClientUsingPublicKey: { _, _, _, _ in MockedSSHClient() },
			execute: execute)
	}

	static func throwingCommand(result: SSHExecutionResult) -> Self {
		return Self(
			getClientUsingPassword: { _, _, _ in MockedSSHClient() },
			getClientUsingPublicKey: { _, _, _, _ in MockedSSHClient() },
			execute: { _, command in
				return AsyncThrowingStream { continuation in
					switch result {
					case .result(let result):
						continuation.yield(CommandOutput.standardOutput(ByteBuffer(string: result)))
						continuation.finish()
					case .softThrow(let error):
						continuation.yield(CommandOutput.standardError(ByteBuffer(string: error.localizedDescription)))
						continuation.finish()
					case .throw(let error):
						continuation.finish(throwing: error)
					}
				}
			}
		)
	}
}
