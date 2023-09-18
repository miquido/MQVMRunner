import CryptoKit
import NIO
import NIOSSH

extension P256.Signing.PrivateKey {
	init(buffer: inout ByteBuffer) throws {
		guard
			let check0 = buffer.readInteger(as: UInt32.self),
			let check1 = buffer.readInteger(as: UInt32.self),
			check0 == check1,
			var keyTypeBuffer = buffer.readBuffer(),
			keyTypeBuffer.ensurePrefix("ecdsa-sha2-nistp256"),
			var curveTypeBuffer = buffer.readBuffer(),
			curveTypeBuffer.ensurePrefix("nistp256"),
			let _ = buffer.readBuffer(),
			let privateKeyBufferLength = buffer.readInteger(as: UInt32.self),
			let privateKey = buffer.readBytes(length: Int(privateKeyBufferLength))
		else { throw PrivateKeyParser.DecodingFailure("Failed to decode private key") }
		try self.init(rawRepresentation: privateKey)
	}
}
