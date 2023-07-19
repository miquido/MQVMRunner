import Foundation

extension String {
	var filePathURL: URL {
		if #available(macOS 13.0, *) {
			return URL(filePath: self)
		} else {
			return URL(fileURLWithPath: self)
		}
	}
}
