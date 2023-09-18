import Crypto
import NIO
import NIOSSH

// For format explanation, see https://dnaeon.github.io/openssh-private-key-binary-format
extension Curve25519.Signing.PrivateKey {
	init(buffer: inout ByteBuffer) throws {
		guard
			let check0 = buffer.readInteger(as: UInt32.self),
			let check1 = buffer.readInteger(as: UInt32.self),
			check0 == check1,
			var keyTypeBuffer = buffer.readBuffer(),
			keyTypeBuffer.ensurePrefix("ssh-ed25519"),
			var publicKeyBuffer = buffer.readBuffer(),
			var secretBuffer = buffer.readBuffer(),
			let privateKey = secretBuffer.readBytes(length: 32),
			let publicKeyBytes = secretBuffer.readAllBytes(),
			publicKeyBytes == publicKeyBuffer.readAllBytes()
		else {
			throw PrivateKeyParser.DecodingFailure("Failed to decode private key")
		}
		try self.init(rawRepresentation: privateKey)
	}
}
