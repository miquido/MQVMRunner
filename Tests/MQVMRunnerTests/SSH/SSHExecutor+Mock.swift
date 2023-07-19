import Foundation
import NIOCore
import Citadel

@testable import MQVMRunner

enum SSHExecutionResult {
    case `throw`(error: Error)
    case softThrow(error: Error)
    case result(result: String)
}

extension SSHExecutor {
    static func mock(
        execute: @escaping (SSHClientProtocol, String) async throws
            -> AsyncThrowingStream<ExecCommandOutput, Error>
            = { _, _ in AsyncThrowingStream { _ in Void() }},
        transfer: @escaping (SSHClientProtocol, Input, Output) async throws  -> Void = { _, _, _ in }
    ) -> Self {
        return Self(
            getClientUsingPassword: { _, _, _ in MockedSSHClient()},
            getClientUsingPublicKey: { _, _, _, _ in MockedSSHClient()},
            execute: execute,
            transfer: transfer)
    }
    
    static func throwingCommand(result: SSHExecutionResult) -> Self {
        return Self(
            getClientUsingPassword: { _, _, _ in MockedSSHClient() },
            getClientUsingPublicKey: { _, _, _, _ in MockedSSHClient()},
            execute: { _, command in
                return AsyncThrowingStream { continuation in
                    switch result {
                    case .result(let result):
                        continuation.yield(ExecCommandOutput.stdout(ByteBuffer(string: result)))
                        continuation.finish()
                    case .softThrow(let error):
                        continuation.yield(ExecCommandOutput.stderr(ByteBuffer(string: error.localizedDescription)))
                        continuation.finish()
                    case .throw(let error):
                        continuation.finish(throwing: error)
                    }
                }
            },
            transfer: {_, _, _ in }
        )
    }
}
