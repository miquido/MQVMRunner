import Foundation
@testable import MQVMRunner

final class MockedSFTPClient: SFTPClientProtocol {
    var dummyDisk = [String: Data]()
    
    func write(data: Data, at path: String) async throws {
        dummyDisk[path] = data
    }
}
