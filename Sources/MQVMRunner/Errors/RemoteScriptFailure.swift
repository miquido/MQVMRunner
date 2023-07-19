import Foundation
import MQ

internal struct RemoteScriptFailure: EmojiableError {
	internal var displayableMessage: DisplayableString
	internal let underlyingError: Error
	internal var context: SourceCodeContext
	internal let emoji: String = "🧨"

	internal static func error(
		message: StaticString = "RemoteScriptFailure",
		underlyingError: Error,
		file: StaticString = #fileID,
		line: UInt = #line
	) -> Self {
		let underlyingMessage: String = {
			switch underlyingError {
			case let unidentified as Unidentified:
				return unidentified.underlyingError.localizedDescription
			case let theError as TheError:
				return theError.displayableString.resolved
			default:
				return underlyingError.localizedDescription
			}
		}()

		return Self(
			displayableMessage: .init("Remote script failed: \(underlyingMessage)"),
			underlyingError: underlyingError,
			context: .context(
				message: message,
				file: file,
				line: line
			)
		)
	}
}
