import CryptoKit
import CryptoSwift
import Foundation
import NIO
import NIOSSH
import bcryptc

struct PrivateKeyParser {
	typealias Key = String
	typealias Passphrase = String
	static var current: Self = .default
	var parse: (Key, Passphrase?) throws -> NIOSSHPrivateKey

	func parse(key: Key, passphrase: Passphrase? = nil) throws -> NIOSSHPrivateKey {
		try self.parse(key, passphrase)
	}
}

extension PrivateKeyParser {
	static var `default`: Self {
		.init(
			parse: { key, passphrase in
				var key = key.replacingOccurrences(of: "\n", with: "")
				guard
					key.hasPrefix("-----BEGIN OPENSSH PRIVATE KEY-----"),
					key.hasSuffix("-----END OPENSSH PRIVATE KEY-----")
				else {
					throw DecodingFailure("Invalid key wrapper.")
				}

				key.removeLast("-----END OPENSSH PRIVATE KEY-----".utf8.count)
				key.removeFirst("-----BEGIN OPENSSH PRIVATE KEY-----".utf8.count)

				guard let data = Data(base64Encoded: key) else {
					throw DecodingFailure("Invalid base64 data.")
				}

				var buffer = ByteBuffer(data: data)
				guard
					buffer.ensurePrefix("openssh-key-v1"),
					buffer.readInteger(as: UInt8.self) == 0x00  // null terminated
				else {
					throw DecodingFailure("Invalid key prefix.")
				}

				let cipher = try Cipher(buffer: &buffer)
				let kdf = KeyDerivationFunction(buffer: &buffer)

				guard
					buffer.ensureValue(1),  // number of keys, should be always == 1
					var publicKeyBuffer = buffer.readBuffer(),
					var privateKeyBuffer = buffer.readBuffer()
				else { throw DecodingFailure("Invalid key contents") }

				if let parameters = try DecryptorParametersExtractor.current.extractDecryptorParameters(
					&privateKeyBuffer, kdf, cipher.parameters, passphrase)
				{
					try Decryptor.current.decrypt(&privateKeyBuffer, parameters)
				}

				let keyType = try KeyType(buffer: &publicKeyBuffer)
				return try keyType.privateKey(from: &privateKeyBuffer)
			}
		)
	}

	enum KeyType: String {
		case ed25519 = "ssh-ed25519"
		case ecdsa = "ecdsa-sha2-nistp256"

		init(buffer: inout ByteBuffer) throws {
			guard
				var keyTypeBuffer = buffer.readBuffer(),
				let keyTypeRaw = keyTypeBuffer.readString(length: keyTypeBuffer.readableBytes),
				let keyType = KeyType(rawValue: keyTypeRaw)
			else {
				throw DecodingFailure("Unsupported key type.")
			}

			self = keyType
		}

		func privateKey(from buffer: inout ByteBuffer) throws -> NIOSSHPrivateKey {
			switch self {
			case .ed25519:
				let key = try Curve25519.Signing.PrivateKey(buffer: &buffer)
				return NIOSSHPrivateKey(ed25519Key: key)
			case .ecdsa:
				let key = try P256.Signing.PrivateKey(buffer: &buffer)
				return NIOSSHPrivateKey(p256Key: key)
			}
		}
	}

	struct DecodingFailure: Error {
		let description: String

		init(_ description: String) {
			self.description = description
		}
	}
}
