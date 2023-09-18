import ArgumentParser
import NIOCore
import SimpleSSHClient
import XCTest

@testable import MQVMRunner

final class MQVMRunnerExecuteTests: XCTestCase {
	func testExecute() async throws {
		let ipExpectation = expectation(description: "Command should check the IP")
		let copyFilesExpectation = expectation(description: "Command should copy the files")
		copyFilesExpectation.expectedFulfillmentCount = 2
		let chmodExpectation = expectation(description: "Command should CHMOD the script")
		let rmExpectation = expectation(description: "Command should RM the script")

		var command = command(
			commandExecutor: .mock(
				resultHandler: { _ in
					"Xcode_16.0"
				},
				{
					if $0.command.hasSuffix("tart"), $0.arguments.contains("ip") {
						ipExpectation.fulfill()
					}
				}
			),
			sshExecutor:
				.mock(
					execute: {
						if $1.contains("chmod") {
							chmodExpectation.fulfill()
						}
						if $1.contains("rm") {
							rmExpectation.fulfill()
						}
						return AsyncThrowingStream { continuation in
							continuation.yield(CommandOutput.standardOutput(ByteBuffer(string: String())))
							continuation.finish()
						}
					}
				),
			fileTransfer:
				.mock(
					transfer: { _, _, _ in
						copyFilesExpectation.fulfill()
					}
				)
		)

		try await command.run()

		await fulfillment(of: [ipExpectation, copyFilesExpectation, chmodExpectation, rmExpectation], timeout: 0)
	}

	func testIPFail() async throws {
		let command1 = command(commandExecutor: .mock(defaultResult: ""))
		await checkForError(in: command1, expectedError: GetIPEmpty.self)

		let command2 = command(
			commandExecutor: .mock({ _ in
				throw TartIPError()
			}))
		await checkForError(in: command2, expectedError: TartIPError.self)
	}

	func testCopyFilesFail() async throws {
		let command = command(
			fileTransfer: .mock(transfer: { _, _, _ in throw CopyError() })
		)
		await checkForError(in: command, expectedError: CopyError.self)
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
		sshExecutor: SSHExecutor = .mock(),
		fileTransfer: FileTransfer = .mock()
	) -> AsyncParsableCommand {
		CommandExecutor.current = commandExecutor
		SSHExecutor.current = sshExecutor
		FileTransfer.current = fileTransfer

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

	private struct TartIPError: Error {
	}

	private struct CopyError: Error {
	}

	private struct CleanupError: Error {
	}

	private struct SSHError: Error {
	}
}
