import Foundation
import NIO
import XCTest

@testable import SimpleSSHClient

class DecryptorParametersExtractorTests: XCTestCase {
	func testParametersFromInvalidKDF() throws {
		var buffer = ByteBuffer(repeating: 0, count: 0)
		let result = try DecryptorParametersExtractor.current.extractDecryptorParameters(
			&buffer, .none, .init(keySize: 0, ivSize: 0), nil)
		XCTAssertNil(result)
	}

	func testParametersFromInvalidPassword() throws {
		var buffer = ByteBuffer(repeating: 0, count: 0)
		let result = try DecryptorParametersExtractor.current.extractDecryptorParameters(
			&buffer, .bcrypt(salt: [], rounds: 0), .init(keySize: 0, ivSize: 0), nil)
		XCTAssertNil(result)
	}

	func testParametersFromValidKDF() throws {
		var buffer = ByteBuffer(repeating: 0, count: 0)
		KeyExpansionFunction.current.expand = { _, _, _, _ in
			[
				0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
			]
		}
		let result = try DecryptorParametersExtractor.current.extractDecryptorParameters(
			&buffer, .bcrypt(salt: [], rounds: 0), .init(keySize: 4, ivSize: 12), "password")
		XCTAssertNotNil(result)
		XCTAssertEqual(result?.key, [0x00, 0x01, 0x02, 0x03])
		XCTAssertEqual(
			result?.iv,
			[
				0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
				0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
			])
	}
}
