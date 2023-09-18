import AppKit
import ArgumentParser
import Foundation
import MQ

internal struct Start: ErrorHandlingParsableCommand, IPAble, VMAuthenticable {
	internal static var configuration = CommandConfiguration(
		commandName: "start",
		abstract: "Start a VM instance"
	)

	@Argument(
		help: "Image name"
	)
	internal var image: String

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
		help: """
									Password to account or path to the private key localization
									i.e.: ~/.ssh/MyPrivateKey
									"""
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

	@Option(
		name: .shortAndLong,
		help: "path to `tart` executable"
	)
	internal var tart: String = "/opt/homebrew/bin/tart"

	@Option(
		name: .shortAndLong,
		help: "Xcode version"
	)
	internal var xcode: String?

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

	@Option(
		name: .long,
		help:
			"Mount local directory as Volume in VM. Can be defined multiple times to mount multiple directories. Format: <local_path>=<remote_name>."
	)
	internal var mount: [MountedDirectory] = []

	internal mutating func go() async throws {
		Logger.info("💈", "Starting VM")
		Logger.info("🥧", "VM image = \(image)")

		try cloneImage()
		try runVM()
		try getVMIP(tart: tart, image: jobID)

		try await testConnection()
		try await setXcodeVersion()
	}

	private func cloneImage() throws {
		Logger.info("😐🫥", "Cloning VM image")

		try Command
			.tart(tart, .clone(original: image, cloned: jobID))
			.execute()
	}

	private func runVM() throws {
		Logger.info("🏎", "Running VM")
		var mount = mount
		mount.append(TransferDirectory(identifier: jobID).asMountDirectory)
		let mounts =
			try mount
			.map { try $0.ensureDirectoryExists() }
			.map { $0.asTartOption }

		/// We run the tart VM as a detached process, so the runner does not wait for the children process to exit
		try Command
			.tart(tart, .run(image: jobID, options: mounts))
			.runDetached()
	}

	private func testConnection() async throws {
		Logger.info("🔧", "Testing SSH connection")

		try await SSHExecutor.current.connect(host: ip, user: user, authentication: authentication)
		try await SSHExecutor.current.execute(command: "whoami").waitToFinish()
		Logger.info("🔮", "VM '\(jobID)' is running on ip \(ip)")
	}

	private func setXcodeVersion() async throws {
		Logger.info("🔨", "Checking Xcode version")

		guard let xcode, !xcode.isEmpty, xcode.uppercased() != "LATEST" else {
			Logger.info("🔨", "Using latest Xcode version")
			return
		}

		let regex = try NSRegularExpression(pattern: "^[1-9][0-9]?(\\.[0-9]+){0,2}$")
		let range = NSRange(location: 0, length: xcode.utf16.count)

		guard regex.firstMatch(in: xcode, options: [], range: range) != nil else {
			throw XcodeVersionMismatch.error(xcode: xcode)
		}

		/// This is a shell script executed on VM that checks all available `Xcode` versions
		///
		/// Read contents of `Xcode` `Info.plist`, look for `ShortVersion` and print it
		let xcodeVersionCommand =
			"plutil -p \"$f/Contents/Info.plist\" | grep CFBundleShortVersionString | awk -F\\\" \'{print $4}\'"
		/// Format result as `/Path/to/Xcode.app_Version`
		let echoFormatCommand = "${f}_$(\(xcodeVersionCommand))"
		/// Loop over all `Xcode` apps in `/Applications` folder
		let externalCommand = "for f in /Applications/Xcode*(.)app; do echo \"\(echoFormatCommand)\"; done"
		try await SSHExecutor.current.connect(host: ip, user: user, authentication: authentication)
		let versionsOutput = try await SSHExecutor.current
			.execute(command: externalCommand)
			.collect()
			.compactMap {
				switch $0 {
				case .standardOutput(let output):
					return String(buffer: output)
				case .standardError:
					throw XcodeSelectFail.error()
						.with("Remote command failure.", for: "Reason")
						.with(externalCommand, for: "Command")
				}
			}
			.joined()
			.trimmingCharacters(in: .whitespacesAndNewlines)
			.split(separator: "\n")

		let versions: [String: String] = versionsOutput.compactMap { element in
			let kv = element.split(separator: "_")

			guard kv.count == 2 else {
				return nil
			}

			let key = String(kv[1])
			let value = String(kv[0])
				.trimmingCharacters(in: .init(charactersIn: ".0"))
			return (key, value)
		}

		let versionsString = versions.map { version, path in
			version + (path == "/Applications/Xcode.app" ? " (Latest)" : "")
		}

		Logger.verbose("🔨", "Xcode versions output: \(versionsOutput)")
		Logger.info("🔨", "Available Xcode versions: \(versionsString)")

		guard let versionPath = versions[xcode] else {
			throw XcodeNotFound.error(xcode: xcode)
		}

		guard versionPath != "/Applications/Xcode.app" else {
			Logger.info("🔨", "Using latest Xcode version")
			return
		}

		Logger.info("🔨", "Setting Xcode version to \(xcode)")

		do {
			try await SSHExecutor.current.connect(host: ip, user: user, authentication: authentication)
			try await SSHExecutor.current.execute(command: "sudo xcode-select -s \"\(versionPath)\"").waitToFinish()
			Logger.info("🔨", "Xcode version selected.")
		} catch {
			throw TheErrorMerge(head: XcodeSelectFail.error(), error.asTheError())
				.with("Selecting xcode failed.", for: "Reason")
				.with("sudo xcode-select -s \"\(versionPath)\"", for: "Command")
		}
	}
}
