import CryptoSwift
import Foundation
import NIO
import NIOSSH

enum Cipher: String {
	case none
	case aes128ctr = "aes128-ctr"
	case aes256ctr = "aes256-ctr"

	var keySize: Int {
		switch self {
		case .none:
			return 0
		case .aes128ctr:
			return 16
		case .aes256ctr:
			return 32
		}
	}

	var ivSize: Int {
		switch self {
		case .none:
			return 0
		case .aes128ctr, .aes256ctr:
			return 16
		}
	}

	init(buffer: inout ByteBuffer) throws {
		guard
			let cipherName = buffer.readString(),
			let cipher = Cipher(rawValue: cipherName)
		else {
			throw PrivateKeyParser.DecodingFailure("Unsupported cipher")
		}
		self = cipher
	}
}
