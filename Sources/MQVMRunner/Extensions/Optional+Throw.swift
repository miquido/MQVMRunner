import Foundation

extension Optional {
	internal func `throw`() throws {
		if let error = self as? Error {
			throw error
		}
	}
}
