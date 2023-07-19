import XCTest
import ArgumentParser
import Citadel
import NIOCore

@testable import MQVMRunner

final class MQVMRunnerExecuteTests: XCTestCase {
    func testExecute() async throws {
        let ipExpectation = expectation(description: "Command should check the IP")
        let scpExpectation = expectation(description: "Command should SCP the files")
        scpExpectation.expectedFulfillmentCount = 2
        let chmodExpectation = expectation(description: "Command should CHMOD the script")
        let rmExpectation = expectation(description: "Command should RM the script")
        
        var command = command(commandExecutor: .mock(resultHandler: { _ in
            "Xcode_16.0"
        }, {
            if $0.command.hasSuffix("tart"), $0.arguments.contains("ip") {
                ipExpectation.fulfill()
            }
        }), sshExecutor: .mock(
            execute: {
                if $1.contains("chmod") {
                    chmodExpectation.fulfill()
                }
                if $1.contains("rm") {
                    rmExpectation.fulfill()
                }
                return AsyncThrowingStream { continuation in
                    continuation.yield(ExecCommandOutput.stdout(ByteBuffer(string: String())))
                    continuation.finish()
                }
            },
            transfer: { _, _, _ in
                scpExpectation.fulfill()
            }))
        
        try await command.run()
        
        await fulfillment(of: [ipExpectation, scpExpectation, chmodExpectation, rmExpectation], timeout: 0)
    }
    
    func testIPFail() async throws {
        let command1 = command(commandExecutor: .mock(defaultResult: ""))
        await checkForError(in: command1, expectedError: GetIPEmpty.self)
        
        let command2 = command(commandExecutor: .mock({ _ in
            throw TartIPError()
        }))
        await checkForError(in: command2, expectedError: TartIPError.self)
    }
    
    func testCopyFilesFail() async throws {
        let command = command(
            sshExecutor: .mock(transfer: { _, _, _ in throw SCPError()})
        )
        await checkForError(in: command, expectedError: SCPError.self)
    }
    
    func testRemoteScriptFail() async throws {
        let command = command(
            sshExecutor: .throwingCommand(result: .throw(error: SSHError()))
        )
        await checkForError(in: command, expectedError: RemoteScriptFailure.self)
    }
    
    func testRemoteScriptDoesNotFailOnStdErr() async throws {
        var command = command(
            sshExecutor: .throwingCommand(result: .softThrow(error: SSHError()))
        )
        do {
            try await command.run()
        } catch {
            XCTFail("Command.run() should not fail: \(error.localizedDescription)")
        }
    }
    
    func testSSHFail() async throws {
        let command = command(
            sshExecutor: .throwingCommand(result: .throw(error: SSHError()))
        )
        await checkForError(in: command, expectedError: RemoteScriptFailure.self)
    }
}

extension MQVMRunnerExecuteTests {
    private func command(
        commandExecutor: CommandExecutor = .mock(),
        sshExecutor: SSHExecutor = .mock()
    ) -> AsyncParsableCommand {
        CommandExecutor.current = commandExecutor
        SSHExecutor.current = sshExecutor
        
        var command = Execute(
            timeout: 0
        )
        
        command.jobID = "job"
        command.user = "user"
        command.privateKey = "~/.ssh/id_rsa"
        command.privateKeyPassword = "somePassword"
        command.passwordAuthorization = "password"
        command.command = "execute"
        command.tart = "tart"
        command.verbose = true
        command.colorsDisable = true
        command.emojiDisable = true
        command.timeout = 10
        return command
    }
    
    private struct TartIPError: Error {}
    private struct SCPError: Error {}
    private struct CleanupError: Error {}
    private struct SSHError: Error {}
}
