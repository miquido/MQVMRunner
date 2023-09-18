import CryptoSwift
import Foundation
import NIO
import bcryptc

enum KeyDerivationFunction {
	case none
	case bcrypt(salt: [UInt8], rounds: Int)

	enum Name: String {
		case none
		case bcrypt
	}

	init(buffer: inout ByteBuffer) {
		guard
			let rawName = buffer.readString(),
			let _ = Name(rawValue: rawName),
			var options = buffer.readBuffer()
		else {
			self = .none
			return
		}

		guard
			var saltBuffer = options.readBuffer(),
			let saltBytes = saltBuffer.readAllBytes(),
			let rounds = options.readInteger(as: UInt32.self)
		else {
			self = .none
			return
		}

		self = .bcrypt(salt: saltBytes, rounds: Int(rounds))
	}
}

extension KeyDerivationFunction {
	struct DecryptError: Error {}
}

private extension Slice {
	var asArray: [Element] { Array(self) }
}
