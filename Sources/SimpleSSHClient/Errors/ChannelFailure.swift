import Foundation

struct ChannelFailure: Error {
	let message: String

	init(_ message: String) {
		self.message = message
	}
}
