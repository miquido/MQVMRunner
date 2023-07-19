import Foundation
import MQ

internal struct CommandFailed: EmojiableError {
	internal let error: Error
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "🔥"

	internal static func error(
		message: StaticString = "CommandFailed",
		command: String,
		error: Error,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			error: error,
			displayableMessage: .init("Command `\(command)` failed with error: \(error.localizedDescription)"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
