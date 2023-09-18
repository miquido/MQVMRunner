import CryptoSwift
import NIO

struct Decryptor {
	static var current: Self = .default
	var decrypt: (inout ByteBuffer, DecryptorParameters) throws -> Void
}

extension Decryptor {
	static var `default`: Decryptor {
		Decryptor(
			decrypt: { buffer, parameters in
				let aes = try AES(key: parameters.key, blockMode: CTR(iv: parameters.iv), padding: .noPadding)
				guard let bytes = buffer.readAllBytes() else {
					return
				}
				let result = try aes.decrypt(bytes)
				buffer.clear()
				buffer.writeBytes(result)
			}
		)
	}
}
