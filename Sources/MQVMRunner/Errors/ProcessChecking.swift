import Foundation
import MQ

internal struct ProcessChecking: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "🩻"

	internal static func error(
		message: StaticString = "ProcessChecking",
		jobID: String,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("No process matching jobID \(jobID) found"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
