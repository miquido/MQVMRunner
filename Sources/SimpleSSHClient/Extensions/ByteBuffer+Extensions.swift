import Foundation
import NIO

extension ByteBuffer {
	mutating func ensurePrefix(_ prefix: String) -> Bool {
		guard let string = readString(length: prefix.utf8.count), string == prefix else {
			return false
		}
		return true
	}

	mutating func ensureValue(_ value: UInt32) -> Bool {
		guard let readValue = readInteger(as: UInt32.self), readValue == value else {
			return false
		}
		return true
	}

	/// Read a string from the buffer.
	/// String is preceded with an integer indicating the length of the string.
	mutating func readString() -> String? {
		guard
			let length = getInteger(at: readerIndex, as: UInt32.self),
			let string = getString(at: readerIndex + UInt32.size, length: Int(length))
		else {
			return nil
		}

		moveReaderIndex(forwardBy: UInt32.size + Int(length))
		return string
	}

	/// Read a sub-buffer from the buffer.
	/// Buffer is preceded with an integer indicating the size of the buffer.
	mutating func readBuffer() -> ByteBuffer? {
		guard
			let length = getInteger(at: readerIndex, as: UInt32.self),
			let slice = getSlice(at: readerIndex + UInt32.size, length: Int(length))
		else {
			return nil
		}

		moveReaderIndex(forwardBy: UInt32.size + Int(length))
		return slice
	}

	mutating func readAllBytes() -> [UInt8]? {
		readBytes(length: readableBytes)
	}
}
