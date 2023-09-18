import NIO

struct DecryptorParameters {
	let key: [UInt8]
	let iv: [UInt8]
}

struct CipherParameters {
	let keySize: Int
	let ivSize: Int
}

extension Cipher {
	var parameters: CipherParameters {
		CipherParameters(keySize: keySize, ivSize: ivSize)
	}
}

struct DecryptorParametersExtractor {
	static var current: Self = .default
	var extractDecryptorParameters:
		(inout ByteBuffer, KeyDerivationFunction, CipherParameters, String?) throws -> DecryptorParameters?
}

extension DecryptorParametersExtractor {
	static var `default`: DecryptorParametersExtractor {
		DecryptorParametersExtractor(
			extractDecryptorParameters: { buffer, kdf, cipherParameters, password -> DecryptorParameters? in
				guard case .bcrypt(let salt, let rounds) = kdf, let password = password else {
					return nil
				}
				let resultSize = cipherParameters.keySize + cipherParameters.ivSize
				let data = try KeyExpansionFunction.current.expand(password, salt, UInt32(rounds), resultSize)
				let key = Array(data[0..<cipherParameters.keySize])
				let iv = Array(data[cipherParameters.keySize..<resultSize])
				return DecryptorParameters(key: key, iv: iv)
			}
		)
	}
}
