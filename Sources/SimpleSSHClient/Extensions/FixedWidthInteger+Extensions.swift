import Foundation

extension FixedWidthInteger {
	static var size: Int { MemoryLayout<Self>.size }
}
