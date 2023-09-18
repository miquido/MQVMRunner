import Foundation
@testable import MQVMRunner

extension FileSystem {
	static func mock(
		homeDirectory: @escaping () -> URL = { URL(fileURLWithPath: "/tmp") },
		fileExists: @escaping (URL) -> Bool = { _ in false },
		write: @escaping (String, URL) throws -> Void = { _, _ in },
		remove: @escaping (URL) throws -> Void = { _ in },
		createDirectoryIfNotExists: @escaping (URL) throws -> Void = { _ in },
		copy: @escaping (String, String) throws -> Void = { _, _ in }
	) -> Self {
		.init(
			homeDirectory: homeDirectory,
			fileExists: fileExists,
			write: write,
			remove: remove,
			createDirectoryIfNotExists: createDirectoryIfNotExists,
			copy: copy
		)
	}
}
