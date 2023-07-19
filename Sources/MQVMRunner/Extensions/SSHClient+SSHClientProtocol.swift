import Citadel
import Foundation
import NIOCore

extension SSHClient: SSHClientProtocol {
	func execute(command: String) async throws -> AsyncThrowingStream<ExecCommandOutput, Error> {
		try await executeCommandStream(command)
	}

	func sftpClient() async throws -> SFTPClientProtocol {
		try await openSFTP()
	}
}
