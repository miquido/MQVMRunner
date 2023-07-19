import AppKit
import ArgumentParser
import Foundation
import MQ

internal struct Stop: ErrorHandlingParsableCommand {
	internal static var configuration = CommandConfiguration(
		commandName: "stop",
		abstract: "Stop and cleanup the VM"
	)

	@Argument(
		help: "Pipeline job ID"
	)
	internal var jobID: String

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

	internal mutating func go() throws {
		Logger.info("💈", "Running Cleanup")

		var killError: TheError?
		do {
			try killCurrentTart()
		} catch {
			killError = error.asTheError()
		}

		var removeError: TheError?
		do {
			try removeVMFiles()
		} catch {
			removeError = error.asTheError()
		}

		try TheErrorMerge(killError, removeError).throw()
	}

	private func removeVMFiles() throws {
		Logger.info("🧹", "Removing VM files")

		var deleteError: TheError?
		do {
			try Command
				.tart(tart, .delete(image: jobID))
				.execute()
		} catch {
			deleteError = error.asTheError()
		}

		let vmURL = FileManager
			.default
			.homeDirectoryForCurrentUser
			.appending(directory: ".tart")
			.appending(directory: "vms")
			.appending(directory: jobID)

		guard FileSystem.current.fileExists(vmURL) else {
			if let deleteError {
				throw TheErrorMerge(head: deleteError, ImageChecking.error(jobID: jobID))
			}
			return
		}

		do {
			Logger.warning("🔪", "`tart delete` did not work, removing image")

			try FileSystem.current.remove(vmURL)
		} catch {
			throw TheErrorMerge(tail: error.asTheError(), deleteError)
		}
	}

	private func killCurrentTart() throws {
		Logger.info("✋", "Stopping VM instance")

		var stopError: TheError?
		do {
			try Command
				.tart(tart, .stop(image: jobID))
				.execute()
		} catch {
			stopError = error.asTheError()
		}

		let psResult: String
		do {
			psResult = try Command("/bin/ps", "aux")
				.executeResult()
		} catch {
			throw TheErrorMerge(tail: error.asTheError(), stopError)
		}

		guard
			let line: String =
				psResult
				.trimmingCharacters(in: .whitespacesAndNewlines)
				.split(separator: "\n")
				.first(where: {
					$0.contains("tart run \(jobID)")
				})
				.map(String.init)
		else {
			if let stopError {
				throw TheErrorMerge(head: stopError, ProcessChecking.error(jobID: jobID))
			}
			return
		}

		do {
			Logger.warning("🔪", "`tart stop` did not work, killing process")

			guard
				let pid: pid_t = {
					let arguments = line.split(separator: " ")

					guard arguments.count >= 2 else {
						return nil
					}
					return pid_t(arguments[1])
				}()
			else {
				throw PidParsing.error(output: line)
			}

			guard let runningApp = ApplicationSystem.current.apllicationWithPid(pid) else {
				throw AppPid.error(pid: pid)
			}

			guard runningApp.terminate() else {
				throw AppTermination.error(pid: pid)
			}
		} catch {
			throw TheErrorMerge(tail: error.asTheError(), stopError)
		}
	}
}
