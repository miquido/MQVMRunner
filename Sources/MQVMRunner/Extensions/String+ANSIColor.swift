import Foundation

extension String {
	internal enum ANSIColor: UInt {
		case black = 30
		case red = 31
		case green = 32
		case yellow = 33
		case blue = 34
		case magenta = 35
		case cyan = 36
		case white = 37
		case `default` = 0

		fileprivate func code(bold: Bool) -> String {
			"\u{001B}[\(bold ? 1 : 0);\(rawValue)m"
		}
	}

	internal func ansiColor(_ color: ANSIColor, bold: Bool = false) -> String {
		color.code(bold: bold) + self + ANSIColor.default.code(bold: false)
	}
}
