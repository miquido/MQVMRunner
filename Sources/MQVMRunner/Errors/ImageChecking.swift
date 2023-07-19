import Foundation
import MQ

internal struct ImageChecking: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "🖼️"

	internal static func error(
		message: StaticString = "ImageChecking",
		jobID: String,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("No image matching jobID \(jobID) found"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
