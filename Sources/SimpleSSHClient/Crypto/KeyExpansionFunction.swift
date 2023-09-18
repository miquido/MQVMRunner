import Foundation
import bcryptc

struct KeyExpansionFunction {
	static var current: Self = .default
	typealias Password = String
	typealias Salt = [UInt8]
	typealias Rounds = UInt32
	typealias KeySize = Int
	var expand: (Password, [UInt8], Rounds, KeySize) throws -> [UInt8]

	struct KeyExpansionError: Error {}
}

extension KeyExpansionFunction {
	static var `default`: KeyExpansionFunction {
		.init(
			expand: { password, salt, rounds, keySize in
				let key = UnsafeMutablePointer<UInt8>.allocate(capacity: keySize)
				defer { key.deallocate() }
				guard bcrypt_pbkdf(password, password.count, salt, salt.count, key, keySize, rounds) == 0 else {
					throw KeyExpansionError()
				}
				return Array(UnsafeMutableBufferPointer<UInt8>(start: key, count: keySize))
			}
		)
	}
}
