import Foundation
import MQ

internal struct NoConnectedSSHClient: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "🔌"

	internal static func error(
		message: StaticString = "NoConnectedSSHClient",
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Could not find connected SSH clients."),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
