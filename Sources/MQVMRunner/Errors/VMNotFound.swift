import Foundation
import MQ

internal struct VMNotFound: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "👀"

	internal static func error(
		message: StaticString = "VMNotFound",
		image: String,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Tart VM \(image) not found"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
