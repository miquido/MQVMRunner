import Foundation
import MQ

internal struct CommandTermination: EmojiableError {
	internal let code: Int32
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "💥"

	internal static func error(
		message: StaticString = "CommandTermination",
		command: String,
		code: Int32,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			code: code,
			displayableMessage: .init("Command `\(command)` failed with code \(code)"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
