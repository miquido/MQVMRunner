import Foundation
import MQ

internal struct GetIPEmpty: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "📭"

	internal static func error(
		message: StaticString = "GetIPEmpty",
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Received IP is empty"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
