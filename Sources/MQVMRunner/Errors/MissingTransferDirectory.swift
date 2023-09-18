import Foundation
import MQ

internal struct MissingTransferDirectory: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "🔎"

	internal static func error(
		message: StaticString = "MissingTransferDirectory",
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Transfer directory is missing"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
