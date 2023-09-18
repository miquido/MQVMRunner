import CryptoKit
import Foundation
import NIOSSH
import XCTest

@testable import SimpleSSHClient

class PrivateKeyParserTests: XCTestCase {
	override class func setUp() {
		super.setUp()
		KeyExpansionFunction.current = .default
	}

	func testDecodingED25119() throws {
		let privateKey = """
									-----BEGIN OPENSSH PRIVATE KEY-----
									b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
									QyNTUxOQAAACDwrUbUyWnoDJZJ8VHCEBCrbRovYFbXodH39C7I86SgPgAAAJjGzmo9xs5q
									PQAAAAtzc2gtZWQyNTUxOQAAACDwrUbUyWnoDJZJ8VHCEBCrbRovYFbXodH39C7I86SgPg
									AAAEBWg3yJoN/PgdOUfrERuLbsVnvIZ/SmosdfmnqKOvynz/CtRtTJaegMlknxUcIQEKtt
									Gi9gVteh0ff0LsjzpKA+AAAAD0VEIHdpdGhvdXQgcGFzcwECAwQFBg==
									-----END OPENSSH PRIVATE KEY-----
									"""
		let publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPCtRtTJaegMlknxUcIQEKttGi9gVteh0ff0LsjzpKA+"

		let nioSSHPrivateKey = try PrivateKeyParser.current.parse(key: privateKey)
		XCTAssertEqual(nioSSHPrivateKey.publicKey, try NIOSSHPublicKey(openSSHPublicKey: publicKey))
	}

	func testDecodingECDSA() throws {
		let privateKey = """
									-----BEGIN OPENSSH PRIVATE KEY-----
									b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAaAAAABNlY2RzYS
									1zaGEyLW5pc3RwMjU2AAAACG5pc3RwMjU2AAAAQQRRW1F22HIUkSWIDKgKkOCzMcw9iOd5
									O/e8KkCru8tmVbJ7+5Tuxru0CTm/CgcCIF2zwWgaLBNsVG1yXKBMH26YAAAA0CMRmvAjEZ
									rwAAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFFbUXbYchSRJYgM
									qAqQ4LMxzD2I53k797wqQKu7y2ZVsnv7lO7Gu7QJOb8KBwIgXbPBaBosE2xUbXJcoEwfbp
									gAAAAgThETDbnl89woV0gtMlNKHO8KwiNZNjBZrRxqJSrROIoAAAA0bWFyY2luLmR6aWVu
									bmlrQE1hY0Jvb2stUHJvLW1hcmNpbmR6aWVubmlrLTQ5MS5sb2NhbAECAwQ=
									-----END OPENSSH PRIVATE KEY-----
									"""
		let publicKey =
			"ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFFbUXbYchSRJYgMqAqQ4LMxzD2I53k797wqQKu7y2ZVsnv7lO7Gu7QJOb8KBwIgXbPBaBosE2xUbXJcoEwfbpg="
		let nioSSHPrivateKey = try PrivateKeyParser.current.parse(key: privateKey)
		XCTAssertEqual(nioSSHPrivateKey.publicKey, try NIOSSHPublicKey(openSSHPublicKey: publicKey))
	}

	func testDecodingECDSAWithPassphrase() throws {
		let privateKey = """
									-----BEGIN OPENSSH PRIVATE KEY-----
									b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABAElm0zQS
									cpNo9CIu3PVfJpAAAAEAAAAAEAAABoAAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlz
									dHAyNTYAAABBBEgwfhch26jEq9k2ri7HpJanKNDR7dKRo5reLy2522mR5W9wzUBNIhBr/A
									eeAJuqNmgsOteitxz8nyi9Tf4k0TYAAADQFSUJihsP1ic7FLsxy6yaqmDrJA1xbSVJZxk4
									ERsqyVMY9hK2GcgX3ikYAJI5SpVj/HHsgRhKOkmrg5mMhuWezQKudnq8MxqQIVfxetJJ/V
									XZUit0DtmyBgc/g5bGeGWnO4nAjEX4Siygzbcmcg4jlPoPpj9Kbt9qytDo2ivdB5nrrZcS
									gsRBos/YDafcloJ4GpEWn8u85mExpQCR7gyxsK7IXnzuVaQuVf4i2A8qqK2lD89wb5u5gk
									CwW54+T9aF+pmuOhTecOfegz3cjkpw5Q==
									-----END OPENSSH PRIVATE KEY-----
									"""
		let publicKey =
			"ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEgwfhch26jEq9k2ri7HpJanKNDR7dKRo5reLy2522mR5W9wzUBNIhBr/AeeAJuqNmgsOteitxz8nyi9Tf4k0TY="
		let nioSSHPrivateKey = try PrivateKeyParser.current.parse(privateKey, "tester")
		XCTAssertEqual(nioSSHPrivateKey.publicKey, try NIOSSHPublicKey(openSSHPublicKey: publicKey))
	}

	func testDecodingECDSAWithInvalidPassphrase() throws {
		let privateKey = """
									-----BEGIN OPENSSH PRIVATE KEY-----
									b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABAElm0zQS
									cpNo9CIu3PVfJpAAAAEAAAAAEAAABoAAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlz
									dHAyNTYAAABBBEgwfhch26jEq9k2ri7HpJanKNDR7dKRo5reLy2522mR5W9wzUBNIhBr/A
									eeAJuqNmgsOteitxz8nyi9Tf4k0TYAAADQFSUJihsP1ic7FLsxy6yaqmDrJA1xbSVJZxk4
									ERsqyVMY9hK2GcgX3ikYAJI5SpVj/HHsgRhKOkmrg5mMhuWezQKudnq8MxqQIVfxetJJ/V
									XZUit0DtmyBgc/g5bGeGWnO4nAjEX4Siygzbcmcg4jlPoPpj9Kbt9qytDo2ivdB5nrrZcS
									gsRBos/YDafcloJ4GpEWn8u85mExpQCR7gyxsK7IXnzuVaQuVf4i2A8qqK2lD89wb5u5gk
									CwW54+T9aF+pmuOhTecOfegz3cjkpw5Q==
									-----END OPENSSH PRIVATE KEY-----
									"""
		
		XCTAssertThrowsError(
			try PrivateKeyParser.current.parse(key: privateKey, passphrase: "test"),
			"Should throw an error on invalid passphrase")
	}

	func testDecodingWithInvalidKeyWrapper() throws {
		var invalidPrivateKey = "qwertyuiopasdfghjklzxcvbnm"
		XCTAssertThrowsError(
			try PrivateKeyParser.current.parse(key: invalidPrivateKey), "Should throw an error on invalid key wrapper")

		invalidPrivateKey = "-----BEGIN OPENSSH PRIVATE KEY-----qwertyuiopasdfghjklzxcvbnm"
		XCTAssertThrowsError(
			try PrivateKeyParser.current.parse(key: invalidPrivateKey), "Should throw an error on invalid key wrapper")
	}

	func testDecodingWithInvalidBase64Data() throws {
		let invalidPrivateKey = """
						-----BEGIN OPENSSH PRIVATE KEY-----
						qwertyuiopasdfghjklzxcvbnm
						-----END OPENSSH PRIVATE KEY-----
						"""
		XCTAssertThrowsError(
			try PrivateKeyParser.current.parse(key: invalidPrivateKey),
			"Should throw an error on invalid key prefix")
	}

	func testDecodingWithInvalidPrefix() throws {
		let data = "openssh-key-v2".data(using: .utf8)! + Data([0x00])
		let base64Data = data.base64EncodedString()
		let invalidPrivateKey = wrap(key: base64Data)
		XCTAssertThrowsError(
			try PrivateKeyParser.current.parse(key: invalidPrivateKey),
			"Should throw an error on invalid key prefix")
	}

	func testDecodingWithInvalidNumberOfKeys() throws {
		var data = Data()
		data.append("openssh-key-v1".data(using: .utf8)!)
		data += UInt8(0x00)
		data.append("none")
		data.append(UInt32(2).data)

		let base64Data = data.base64EncodedString()
		let invalidPrivateKey = wrap(key: base64Data)

		XCTAssertThrowsError(
			try PrivateKeyParser.current.parse(key: invalidPrivateKey),
			"Should throw an error on invalid number of keys")
	}

	func testDecodingWithInvalidPublicKeyContents() throws {
		var data = Data()
		data.append("openssh-key-v1".data(using: .utf8)!)
		data += UInt8(0x00)
		data.append("none")
		data.append(UInt32(1).data)

		let base64Data = data.base64EncodedString()
		let invalidPrivateKey = wrap(key: base64Data)
		XCTAssertThrowsError(
			try PrivateKeyParser.current.parse(key: invalidPrivateKey),
			"Should throw an error on invalid number of keys")
	}

	func testDecodingWithInvalidPrivateKeyContents() throws {
		var data = Data()
		data.append("openssh-key-v1".data(using: .utf8)!)
		data += UInt8(0x00)
		data.append("none")
		data.append("none")
		data += UInt32(0x00)
		data += UInt32(0x01)
		data.append("abcd")

		let base64Data = data.base64EncodedString()
		let invalidPrivateKey = wrap(key: base64Data)
		XCTAssertThrowsError(
			try PrivateKeyParser.current.parse(key: invalidPrivateKey),
			"Should throw an error on invalid number of keys")
	}

	func testDecodingWithInvalidKeyType() throws {
		var data = Data()
		data.append("openssh-key-v1".data(using: .utf8)!)
		data += UInt8(0x00)
		data.append("none")
		data.append("none")
		data += UInt32(0x00)
		data += UInt32(0x01)
		data.append("abcd")
		data.append("efgh")

		let base64Data = data.base64EncodedString()
		let invalidPrivateKey = wrap(key: base64Data)
		XCTAssertThrowsError(
			try PrivateKeyParser.current.parse(key: invalidPrivateKey),
			"Should throw an error on invalid number of keys")
	}
}

extension PrivateKeyParserTests {
	func encode(key: String) -> String {
		let data = Data(key.utf8)
		return data.base64EncodedString()
	}

	func wrap(key: String) -> String {
		"""
				-----BEGIN OPENSSH PRIVATE KEY-----
				\(key)
				-----END OPENSSH PRIVATE KEY-----
				"""
	}
}

private extension Data {
	mutating func append(_ string: String) {
		let length = UInt32(string.utf8.count)
		append(length.data)
		append(string.data(using: .utf8)!)
	}

	static func += (lhs: inout Data, rhs: UInt8) {
		lhs.append(rhs)
	}

	static func += (lhs: inout Data, rhs: UInt32) {
		lhs.append(rhs.data)
	}
}

private extension UInt32 {
	var data: Data {
		var value = self.bigEndian
		return Data(bytes: &value, count: UInt32.size)
	}
}
