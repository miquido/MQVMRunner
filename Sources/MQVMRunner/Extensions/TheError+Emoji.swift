import Foundation
import MQ

internal protocol EmojiableError: TheError, CustomErrorMerge {
	var emoji: String { get }
}

extension EmojiableError {
	internal var mergeMessage: DisplayableString {
		guard Logger.emojis else {
			return displayableString
		}

		return .init(
			"\(emoji) \(displayableString.resolved)"
		)
	}
}
