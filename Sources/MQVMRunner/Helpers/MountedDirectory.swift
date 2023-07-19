import ArgumentParser
import Foundation

struct MountedDirectory: ExpressibleByArgument {
	let path: String
	let mountName: String

	var asTartOption: Command.Tart.Option {
		.mount(directory: path, to: mountName)
	}

	init?(argument: String) {
		let components = argument.split(separator: "=").map(String.init)
		guard components.count == 2 else {
			return nil
		}
		path = components[0].expandingTildeInPath
		mountName = components[1]
	}
}

extension MountedDirectory {
	@discardableResult
	func ensureDirectoryExists() throws -> Self {
		let directoryURL = URL(fileURLWithPath: self.path)
		try FileSystem.current.createDirectoryIfNotExists(directoryURL)
		return self
	}
}

private extension String {
	var expandingTildeInPath: String {
		(self as NSString).expandingTildeInPath
	}
}
