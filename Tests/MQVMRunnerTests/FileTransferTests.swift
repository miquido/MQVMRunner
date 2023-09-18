import XCTest
import NIO
@testable import MQVMRunner
import SimpleSSHClient

class FileTransferTests: XCTestCase {
	override class func tearDown() {
		FileSystem.current = .default
		SSHExecutor.current = .default
	}

	func testShouldRemoveExistingFileIfExists() async throws {
		let fileExists = XCTestExpectation(description: "Should check for existing file")
		let fileRemove = XCTestExpectation(description: "Should remove existing file if exists")
		let moveFile = XCTestExpectation(description: "Should move file")
		let transferDirectory = TransferDirectory(identifier: "test")
		FileSystem.current = .mock(
			fileExists: { _ in
				fileExists.fulfill()
				return true
			},
			remove: { url in
				var targetURL = transferDirectory.path.filePathURL
				targetURL.appendPathComponent("b")
				XCTAssertEqual(url, targetURL)
				fileRemove.fulfill()
			}
		)
		SSHExecutor.current = .mock { _, _ in
			moveFile.fulfill()
			return AsyncThrowingStream { continuation in continuation.finish() }
		}
		try await SSHExecutor.current.connect(host: "", user: "", authentication: .password(user: "", password: ""))
		try await FileTransfer.current.transfer(input: "a", output: "b", using: transferDirectory)
		await fulfillment(of: [fileExists, fileRemove, moveFile])
	}
}
