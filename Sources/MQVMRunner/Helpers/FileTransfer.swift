struct FileTransfer {
	static var current: FileTransfer = .default
	let transfer: (String, String, TransferDirectory) async throws -> Void
}

extension FileTransfer {
	static var `default`: FileTransfer {
		FileTransfer(
			transfer: { input, output, transferDirectory in
				let targetPath = transferDirectory.path.appendingPathComponent(output)
				let targetURL = targetPath.filePathURL
				if FileSystem.current.fileExists(targetURL) {
					try FileSystem.current.remove(targetURL)
				}

				try FileSystem.current.copy(input, targetPath)
				let remotePath = transferDirectory.remotePath.appendingPathComponent(output)
				try await SSHExecutor.current.execute(command: "mv \"\(remotePath)\" \(output)").waitToFinish()
			}
		)
	}

	func transfer(input: String, output: String, using: TransferDirectory) async throws {
		try await transfer(input, output, using)
	}
}
