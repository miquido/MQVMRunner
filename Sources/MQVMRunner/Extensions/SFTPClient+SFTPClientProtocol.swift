import Citadel
import Foundation
import NIOCore

extension SFTPClient: SFTPClientProtocol {
	func write(data: Data, at path: String) async throws {
		try await withFile(
			filePath: path, flags: [.read, .write, .create],
			{ file in
				try await file.write(ByteBuffer(data: data))
			})
	}
}
