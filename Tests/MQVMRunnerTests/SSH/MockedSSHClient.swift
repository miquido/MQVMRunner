import Foundation
import NIOCore
import Citadel

@testable import MQVMRunner

final class MockedSSHClient: SSHClientProtocol {
    
    var executedCommand: String? = nil
    var sftpClient: MockedSFTPClient? = nil
        
    func execute(command: String) async throws -> AsyncThrowingStream<ExecCommandOutput, Error> {
        executedCommand = command
        return AsyncThrowingStream { continuation in
            continuation.yield(ExecCommandOutput.stdout(ByteBuffer()))
            continuation.finish()
        }
    }
    
    func sftpClient() async throws -> SFTPClientProtocol {
        let sftpClient = MockedSFTPClient()
        self.sftpClient = sftpClient
        return sftpClient
    }
}
