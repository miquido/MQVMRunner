import Foundation
import MQ

internal struct BuildFailed: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "😩"

	internal static func error(
		message: StaticString = "BuildFailed",
		code: Int32,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Build failed, check logs for error (code \(code))."),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
