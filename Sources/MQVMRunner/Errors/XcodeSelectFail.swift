import Foundation
import MQ

internal struct XcodeSelectFail: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "🤔"

	internal static func error(
		message: StaticString = "XcodeSelectFail",
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Command `xcode-select` failed. Did you add `xcode-select` to `sudoers`?"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
