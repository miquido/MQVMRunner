import Foundation
import NIO

public enum CommandOutput {
	case standardOutput(ByteBuffer)
	case standardError(ByteBuffer)
}
