import Foundation
import MQ

internal protocol CustomErrorMerge {
	var mergeMessage: DisplayableString { get }
}

struct ManyErrors: EmojiableError {
	internal let errors: [TheError]
	internal var context: SourceCodeContext
	internal let emoji: String = "📜"

	internal var displayableMessage: DisplayableString {
		.init(
			"Many errors:\n"
				+ mergedMessages
				.map(\.resolved)
				.enumerated()
				.map {
					"\($0.offset + 1): \($0.element)"
				}
				.joined(separator: "\n")
		)
	}

	private var mergedMessages: [DisplayableString] {
		errors.flatMap { error in
			switch error {
			case let many as ManyErrors:
				return many.mergedMessages
			case let custom as CustomErrorMerge:
				return [custom.mergeMessage]
			default:
				return [error.displayableString]
			}
		}
	}
}
// swift-format-ignore: AlwaysUseLowerCamelCase
internal func TheErrorMerge(
	_ optionalErrors: TheError?...
) -> TheError? {
	let errors = optionalErrors.compactMap { $0 }

	guard !errors.isEmpty else {
		return nil
	}
	guard errors.count > 1 else {
		return errors.first
	}

	return ManyErrors(
		errors: errors,
		context: .merging(
			errors.map(\.context)
		)
	)
}
// swift-format-ignore: AlwaysUseLowerCamelCase
internal func TheErrorMerge(
	head: TheError,
	_ optionalErrors: TheError?...
) -> TheError {
	let moreErrors = optionalErrors.compactMap { $0 }
	let errors = [head] + moreErrors

	guard !moreErrors.isEmpty else {
		return head
	}

	return ManyErrors(
		errors: errors,
		context: .merging(
			errors.map(\.context)
		)
	)
}
// swift-format-ignore: AlwaysUseLowerCamelCase
internal func TheErrorMerge(
	tail: TheError,
	_ optionalErrors: TheError?...
) -> TheError {
	let moreErrors = optionalErrors.compactMap { $0 }
	let errors = moreErrors + [tail]

	guard !moreErrors.isEmpty else {
		return tail
	}

	return ManyErrors(
		errors: errors,
		context: .merging(
			errors.map(\.context)
		)
	)
}
