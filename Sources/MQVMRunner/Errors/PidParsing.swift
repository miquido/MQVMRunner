import Foundation
import MQ

internal struct PidParsing: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "🪪"

	internal static func error(
		message: StaticString = "PidParsing",
		output: String,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Could not parse pid from: \(output)"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
