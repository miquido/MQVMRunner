import Foundation
import MQ

internal struct AppPid: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal var context: SourceCodeContext
	internal let emoji: String = "📇"

	internal static func error(
		message: StaticString = "AppPid",
		pid: pid_t,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		Self(
			displayableMessage: .init("Could not get app with pid \(pid)"),
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
