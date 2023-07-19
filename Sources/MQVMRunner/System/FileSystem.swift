import Foundation

internal struct FileSystem {
	internal static var current: FileSystem = .default

	internal let homeDirectory: () -> URL
	internal let fileExists: (URL) -> Bool
	internal let write: (String, URL) throws -> Void
	internal let remove: (URL) throws -> Void
	internal let createDirectoryIfNotExists: (URL) throws -> Void
}

extension FileSystem {
	internal static var `default`: Self {

		func homeDirectory() -> URL {
			FileManager
				.default
				.homeDirectoryForCurrentUser
		}

		func fileExists(at url: URL) -> Bool {
			FileManager.default.fileExists(atPath: url.getPath())
		}

		func write(content: String, to url: URL) throws {
			try content.write(to: url, atomically: true, encoding: .utf8)
		}

		func remove(at url: URL) throws {
			try FileManager.default.removeItem(at: url)
		}

		func createDirectoryIfNotExists(at url: URL) throws {
			if !fileExists(at: url) {
				try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
			}
		}

		return .init(
			homeDirectory: homeDirectory,
			fileExists: fileExists(at:),
			write: write(content:to:),
			remove: remove(at:),
			createDirectoryIfNotExists: createDirectoryIfNotExists(at:)
		)
	}
}
