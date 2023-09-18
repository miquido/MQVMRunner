import Foundation
import NIOCore
import SimpleSSHClient

protocol SSHClientProtocol {
	func execute(command: String, timeout: UInt) async throws -> AsyncThrowingStream<CommandOutput, Error>
}

extension SimpleSSHClient: SSHClientProtocol {}
