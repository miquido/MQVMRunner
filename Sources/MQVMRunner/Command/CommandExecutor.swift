import Foundation

internal struct CommandExecutor {
	internal static var current: CommandExecutor = .default

	internal var execute: (Command) throws -> Void
	internal var executeResult: (Command) throws -> String
	internal var runDetached: (Command) throws -> Void

	internal init(
		execute: @escaping (Command) throws -> Void,
		executeResult: @escaping (Command) throws -> String,
		runDetached: @escaping (Command) throws -> Void
	) {
		self.execute = execute
		self.executeResult = executeResult
		self.runDetached = runDetached
	}
}

extension CommandExecutor {
	internal static var `default`: Self {
		let outputHandle: FileHandle? = .standardOutput
		let errorHandle: FileHandle? = .standardError

		func execute(_ command: Command) throws {
			let process = Process()
			process.launchPath = command.command
			process.arguments = command.arguments
			process.standardOutput = outputHandle
			process.standardError = errorHandle

			Logger.verbose(nil, "Command `\(command.string)` is being executed now with output.")

			do {
				try process.run()
			} catch {
				throw CommandFailed.error(command: command.string, error: error)
			}

			process.waitUntilExit()

			Logger.verbose(
				nil, "Command `\(command.string)` finished executing with status code: \(process.terminationStatus)")

			guard process.terminationStatus == 0 else {
				throw CommandTermination.error(
					command: command.string,
					code: process.terminationStatus
				)
			}
		}

		func executeResult(_ command: Command) throws -> String {
			let pipe = Pipe()
			let group = DispatchGroup()
			let semaphore = DispatchSemaphore(value: 0)
			var standardOutData = Data()
			let queue = DispatchQueue.global()

			group.enter()
			let process = Process()
			process.launchPath = command.command
			process.arguments = command.arguments
			process.standardOutput = pipe.fileHandleForWriting
			process.standardError = errorHandle
			process.terminationHandler = { _ in
				process.terminationHandler = nil
				group.leave()
			}

			group.enter()
			queue.async {
				let data = pipe.fileHandleForReading.readDataToEndOfFile()
				pipe.fileHandleForReading.closeFile()

				standardOutData = data
				group.leave()
			}

			group.notify(queue: queue) {
				semaphore.signal()
			}

			Logger.verbose(nil, "Command `\(command.string)` is being executed now.")

			do {
				try process.run()
			} catch {
				throw CommandFailed.error(command: command.string, error: error)
			}

			process.waitUntilExit()

			Logger.verbose(
				nil, "Command `\(command.string)` finished executing with status code: \(process.terminationStatus)")

			guard process.terminationStatus == 0 else {
				throw CommandTermination.error(
					command: command.string,
					code: process.terminationStatus
				)
			}

			pipe.fileHandleForReading.closeFile()

			semaphore.wait()

			let string = String(decoding: standardOutData, as: UTF8.self)
			return string
		}

		func runDetached(_ command: Command) throws {
			Logger.verbose(nil, "Command `\(command.string)` will run now.")

			let process = Process()
			process.launchPath = command.command
			process.arguments = command.arguments

			/// setting `/dev/null` for all three `stdin`, `stdout` and `stderr` is necessary for the process to be disowned from the parent
			process.standardInput = FileHandle.nullDevice
			process.standardOutput = FileHandle.nullDevice
			process.standardError = FileHandle.nullDevice

			do {
				try process.run()
			} catch {
				throw CommandFailed.error(command: command.string, error: error)
			}
		}

		return .init(
			execute: execute(_:),
			executeResult: executeResult(_:),
			runDetached: runDetached(_:)
		)
	}
}
