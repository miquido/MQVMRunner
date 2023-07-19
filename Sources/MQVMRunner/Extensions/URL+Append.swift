import Foundation

extension URL {
	internal func appending(directory: String) -> URL {
		if #available(macOS 13.0, *) {
			return appending(path: directory, directoryHint: .isDirectory)
		} else {
			var url = self
			url.appendPathComponent(directory, isDirectory: true)
			return url
		}
	}
}
