import ArgumentParser
import Foundation
import MQ

internal struct Execute: ErrorHandlingParsableCommand, IPAble, VMAuthenticable {
	internal static var configuration = CommandConfiguration(
		commandName: "execute",
		abstract: "Execute a command on the VM"
	)

	@Argument(
		help: "Pipeline job ID"
	)
	internal var jobID: String

	@Argument(
		help: "User name"
	)
	internal var user: String

	@Option(
		name: .long,
		help: "Password to account or path to the private key localization i.e.: ~/.ssh/MyPrivateKey"
	)
	internal var privateKey: String?

	@Option(
		name: .long,
		help: "Password to decipher private key. Only used in private key SSH authorization. Empty string by default."
	)
	internal var privateKeyPassword: String?

	@Option(
		name: .long,
		help: "Password to authorize through SSH using user/password method."
	)
	internal var passwordAuthorization: String?

	@Argument(
		help: "Command to execute on the virtual machine"
	)
	internal var command: String

	@Option(
		name: .shortAndLong,
		help: "path to `tart` executable"
	)
	internal var tart: String = "/opt/homebrew/bin/tart"

	@Flag(
		name: .shortAndLong,
		help: "Print verbose informations."
	)
	internal var verbose: Bool = false

	@Flag(
		name: .long,
		help: "Disable colors in logs."
	)
	internal var colorsDisable: Bool = false

	@Flag(
		name: .long,
		help: "Disable emoji in logs."
	)
	internal var emojiDisable: Bool = false

	internal var ip: String = ""

	@Option(
		name: .customLong("startup-timeout"),
		help: "Timeout for getting VM IP address. Defaults to 10 seconds."
	)
	internal var timeout: UInt = 10

	private var transferDirectory: TransferDirectory { TransferDirectory(identifier: jobID) }

	internal mutating func go() async throws {
		Logger.info("💈", "Running execute")

		try getVMIP(tart: tart, image: jobID)
		try generateWrappingScript()

		try await copyFilesToVM()

		let remoteError = await runRemoteScript()
		let cleanupError = await cleanup()

		try TheErrorMerge(remoteError, cleanupError).throw()
	}

	private func generateWrappingScript() throws {
		Logger.info("🎁", "Generating wrapping script")
		// swift-format-ignore
		let remoteScript = """
			#!/bin/zsh
			security unlock-keychain -p test ~/Library/Keychains/login.keychain-db
			source ~/main_script
			"""

		let remoteScriptURL = URL(fileURLWithPath: "/tmp/\(jobID)_remote_script.sh")
		try FileSystem.current.write(remoteScript, remoteScriptURL)
	}

	private func copyFilesToVM() async throws {
		Logger.info("🗂️", "Copying main_script to VM")
		try await SSHExecutor.current.connect(host: ip, user: user, authentication: authentication)
		try await FileTransfer.current.transfer(input: command, output: "main_script", using: transferDirectory)

		Logger.info("🗂️", "Copying wrapping script to VM")
		try await SSHExecutor.current.connect(host: ip, user: user, authentication: authentication)
		try await FileTransfer.current.transfer(
			input: "/tmp/\(jobID)_remote_script.sh",
			output: "script",
			using: transferDirectory
		)
	}

	private func runRemoteScript() async -> TheError? {
		Logger.info("🏃", "Running script on VM")

		do {
			try await SSHExecutor.current.connect(host: ip, user: user, authentication: authentication)
			try await SSHExecutor.current.execute(command: "chmod +x ./script; ./script")
				.output(
					stdOut: Logger.colorizedInfo,
					stdErr: Logger.colorizedError
				)
		} catch let terminationError as CommandTermination {
			return BuildFailed.error(code: terminationError.code)
		} catch {
			return RemoteScriptFailure.error(underlyingError: error)
		}
		return nil
	}

	private func cleanup() async -> TheError? {
		Logger.info("🧹", "Cleaning script file")

		do {
			try await SSHExecutor.current.connect(host: ip, user: user, authentication: authentication)
			try await SSHExecutor.current.execute(command: "rm ./script").waitToFinish()
		} catch {
			return error.asTheError()
		}
		return nil
	}
}
