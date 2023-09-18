import Foundation

struct TransferDirectory {
	let identifier: String

	var path: String {
		"/tmp/\(identifier)_mqvmrunner"
	}

	var mountName: String {
		"mqvmrunner_internal"
	}

	var remotePath: String {
		"/Volumes/My Shared Files/\(mountName)"
	}

	var asMountDirectory: MountedDirectory {
		.init(name: mountName, path: path)
	}
}
