import Foundation

extension String {
	func appendingPathComponent(_ pathComponent: String) -> String {
		(self as NSString).appendingPathComponent(pathComponent)
	}
}
