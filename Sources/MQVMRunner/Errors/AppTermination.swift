import Foundation
import MQ

internal struct AppTermination: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "🤖"

	internal static func error(
		message: StaticString = "AppTermination",
		pid: pid_t,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Error while terminating the process \(pid)"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
