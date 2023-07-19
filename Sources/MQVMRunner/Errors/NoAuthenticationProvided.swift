import Foundation
import MQ

internal struct NoAuthenticationProvided: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "🔒"

	internal static func error(
		message: StaticString = "NoAuthenticationProvided",
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("No authentication provided."),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
