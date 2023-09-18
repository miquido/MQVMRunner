import Foundation

internal protocol LoggerConfigurator {
	var verbose: Bool { get }
	var colorsDisable: Bool { get }
	var emojiDisable: Bool { get }
}

internal enum Logger {
	private(set) internal static var verboseLogging: Bool = false
	private(set) internal static var colors: Bool = true
	private(set) internal static var emojis: Bool = true

	internal static func configure(_ configurator: LoggerConfigurator) {
		verboseLogging = configurator.verbose
		colors = !configurator.colorsDisable
		emojis = !configurator.emojiDisable
	}

	internal static func info(_ emoji: String? = nil, _ message: String) {
		guard let data = getMessage(emoji: emoji, content: message, level: .info) else {
			return
		}
		FileHandle.standardOutput.write(data)
	}

	internal static func colorizedInfo(_ message: String) {
		guard let data = getColorizedMessage(content: message, level: .info) else {
			return
		}
		FileHandle.standardOutput.write(data)
	}

	internal static func verbose(_ emoji: String? = nil, _ message: String) {
		guard verboseLogging else {
			return
		}

		guard let data = getMessage(emoji: emoji, content: message, level: .verbose) else {
			return
		}
		FileHandle.standardOutput.write(data)
	}

	internal static func warning(_ emoji: String? = nil, _ message: String) {
		guard let data = getMessage(emoji: emoji, content: message, level: .warning) else {
			return
		}
		FileHandle.standardOutput.write(data)
	}

	internal static func error(_ emoji: String? = nil, _ message: String) {
		guard let data = getMessage(emoji: emoji, content: message, level: .error) else {
			return
		}
		FileHandle.standardError.write(data)
	}

	internal static func colorizedError(_ message: String) {
		guard let data = getColorizedMessage(content: message, level: .error) else {
			return
		}
		FileHandle.standardError.write(data)
	}

	private static func getColorizedMessage(
		content: String,
		level: LogLevel
	) -> Data? {
		let body = colorize(content, with: level.contentColor, bold: false)
		return body.data(using: .utf8)
	}

	private static func getMessage(
		emoji: String?,
		content: String,
		level: LogLevel
	) -> Data? {
		let label = colors ? "" : " \(level.label)"
		let head = colorize("[\(date)]\(label):", with: level.headColor, bold: true)
		let body = colorize(content, with: level.contentColor, bold: false)
		let emojiPart: String = {
			guard let emoji, emojis else {
				return ""
			}
			return "\(emoji) "
		}()

		let message = "\(head) \(emojiPart)\(body)\n"
		return message.data(using: .utf8)
	}

	private static var date: String {
		Date().formatted(date: .omitted, time: .standard)
	}

	private static func colorize(_ string: String, with color: String.ANSIColor?, bold: Bool) -> String {
		guard colors else {
			return string
		}
		guard let color else {
			return string
		}
		return string.ansiColor(color)
	}
}

extension Logger {
	fileprivate enum LogLevel {
		case info
		case verbose
		case warning
		case error

		var label: String {
			switch self {
			case .info:
				return "INFO"
			case .verbose:
				return "VERBOSE"
			case .warning:
				return "WARNING"
			case .error:
				return "ERROR"
			}
		}

		var headColor: String.ANSIColor? {
			switch self {
			case .info:
				return .green
			case .verbose:
				return .magenta
			case .warning:
				return .yellow
			case .error:
				return .red
			}
		}

		var contentColor: String.ANSIColor? {
			switch self {
			case .info:
				return .green
			default:
				return headColor
			}
		}
	}
}
