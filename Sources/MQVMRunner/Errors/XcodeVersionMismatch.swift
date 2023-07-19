import Foundation
import MQ

internal struct XcodeVersionMismatch: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "💔"

	internal static func error(
		message: StaticString = "XcodeVersionMismatch",
		xcode: String,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Xcode version does not match the format: \(xcode)"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
