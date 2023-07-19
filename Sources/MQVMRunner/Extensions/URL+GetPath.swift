import Foundation

extension URL {
	internal func getPath() -> String {
		if #available(macOS 13.0, *) {
			return path(percentEncoded: false)
		} else {
			return path
		}
	}
}
