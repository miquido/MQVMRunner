import Foundation

@testable import MQVMRunner

extension FileTransfer {
	static func mock(transfer: @escaping (String, String, TransferDirectory) throws -> Void = { _, _, _ in }) -> Self {
		.init(transfer: transfer)
	}
}
