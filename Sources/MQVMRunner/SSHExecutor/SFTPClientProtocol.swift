import Citadel
import Foundation
import NIOCore

protocol SFTPClientProtocol {
	func write(data: Data, at path: String) async throws
}
