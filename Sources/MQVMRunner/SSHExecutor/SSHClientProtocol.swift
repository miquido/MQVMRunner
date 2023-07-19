import Citadel
import Foundation
import NIOCore

protocol SSHClientProtocol {
	func execute(command: String) async throws -> AsyncThrowingStream<ExecCommandOutput, any Error>
	func sftpClient() async throws -> SFTPClientProtocol
}
