import ArgumentParser
import NIOCore
import SimpleSSHClient
import XCTest

@testable import MQVMRunner

final class MQVMRunnerStartTests: XCTestCase {
	func testExecute() async throws {
		let cloneExpectation = expectation(description: "Command should Clone the image")
		let runExpectation = expectation(description: "Command should run the VM")
		let ipExpectation = expectation(description: "Command should check the IP")
		let sshTestExpectation = expectation(description: "Command should test the SSH connection")
		let xcodeVersionExpectation = expectation(description: "Command should get the Xcode versions")
		let xcodeSelectExpectation = expectation(description: "Command should set the Xcode version")

		var command = command(
			commandExecutor: .mock(
				resultHandler: { _ in
					"Xcode_16.0"
				},
				{
					if $0.command.hasSuffix("tart"), $0.string.contains("clone") {
						cloneExpectation.fulfill()
					}
					if $0.command.hasSuffix("tart"), $0.string.contains("run") {
						runExpectation.fulfill()
					}
					if $0.command.hasSuffix("tart"), $0.arguments.contains("ip") {
						ipExpectation.fulfill()
					}
				}),
			sshExecutor: .mock(execute: {
				if $1.contains("whoami") {
					sshTestExpectation.fulfill()
				}
				if $1.contains("awk") {
					xcodeVersionExpectation.fulfill()
				}
				if $1.contains("xcode-select") {
					xcodeSelectExpectation.fulfill()
				}
				return AsyncThrowingStream { continuation in
					continuation.yield(CommandOutput.standardOutput(ByteBuffer(string: "Xcode_16.0")))
					continuation.finish()
				}
			})
		)

		try await command.run()

		await fulfillment(of: [
			cloneExpectation,
			runExpectation,
			ipExpectation,
			sshTestExpectation,
			xcodeSelectExpectation,
			xcodeVersionExpectation,
		])
	}

	func testCloneFail() async throws {
		let command = command(
			commandExecutor: .mock({
				if $0.command.hasSuffix("tart"), $0.string.contains("clone") {
					throw CloneError()
				}
			}))
		await checkForError(in: command, expectedError: CloneError.self)
	}

	func testRunFail() async throws {
		let command = command(
			commandExecutor: .mock({
				if $0.command.hasSuffix("tart"), $0.string.contains("run") {
					throw RunError()
				}
			}))
		await checkForError(in: command, expectedError: RunError.self)
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

	func testConnectionFail() async throws {
		let command = command(
			sshExecutor: .throwingCommand(result: .throw(error: ConnectionError()))
		)

		await checkForError(in: command, expectedError: ConnectionError.self)
	}

	func testXcodeVersionFail() async throws {
		let command1 = command(xcode: "2.1.3.7", commandExecutor: .mock())
		await checkForError(in: command1, expectedError: XcodeVersionMismatch.self)

		let command2 = command(
			sshExecutor: .throwingCommand(result: .throw(error: XcodeVersionError()))
		)
		await checkForError(in: command2, expectedError: XcodeVersionError.self)

		let command3 = command(
			sshExecutor: .throwingCommand(result: .result(result: ""))
		)
		await checkForError(in: command3, expectedError: XcodeNotFound.self)

		let command4 = command(
			sshExecutor: .throwingCommand(result: .throw(error: XcodeSelectError()))
		)
		await checkForError(in: command4, expectedError: XcodeSelectError.self)
	}
}

extension MQVMRunnerStartTests {
	private func command(
		xcode: String = "16.0",
		commandExecutor: CommandExecutor = .mock(),
		sshExecutor: SSHExecutor = .mock()
	) -> AsyncParsableCommand {
		CommandExecutor.current = commandExecutor
		SSHExecutor.current = sshExecutor

		var command = Start(
			timeout: 0
		)

		command.image = "image"
		command.jobID = "job"
		command.user = "user"
		command.privateKey = "~/.ssh/id_rsa"
		command.privateKeyPassword = "somePassword"
		command.passwordAuthorization = "password"
		command.tart = "tart"
		command.xcode = xcode
		command.verbose = true
		command.colorsDisable = true
		command.emojiDisable = true
		command.timeout = 10
		command.mount = []

		return command
	}

	private struct CloneError: Error {
	}

	private struct RunError: Error {
	}

	private struct TartIPError: Error {
	}

	private struct ConnectionError: Error {
	}

	private struct XcodeVersionError: Error {
	}

	private struct XcodeSelectError: Error {
	}
}
