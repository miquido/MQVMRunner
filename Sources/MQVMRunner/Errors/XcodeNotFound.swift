import Foundation
import MQ

internal struct XcodeNotFound: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "🔍"

	internal static func error(
		message: StaticString = "XcodeNotFound",
		xcode: String,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Xcode version \(xcode) not found on the VM."),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
