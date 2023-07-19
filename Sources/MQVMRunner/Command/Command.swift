import Foundation

internal struct Command {
	internal let command: String
	internal let arguments: [String]

	internal init(_ command: String, _ args: String...) {
		self.command = command
		self.arguments = args
	}

	internal init(_ command: String, _ args: [String]) {
		self.command = command
		self.arguments = args
	}

	/// Executes the command, waits for exit and writes to selected output
	internal func execute() throws {
		try CommandExecutor.current.execute(self)
	}

	/// Executes the command, waits for exit and returns command output
	@discardableResult internal func executeResult() throws -> String {
		try CommandExecutor.current.executeResult(self)
	}

	/// Executes the command with no `stdin`, `stdout`, `stderr` and without waiting for exit
	internal func runDetached() throws {
		try CommandExecutor.current.runDetached(self)
	}
}

extension Command {
	internal var string: String {
		([command] + arguments).joined(separator: " ")
	}
}
