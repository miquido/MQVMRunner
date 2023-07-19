import XCTest
import ArgumentParser

extension XCTestCase {
    func checkForError<E: Error>(in command: AsyncParsableCommand, expectedError: E.Type) async {
        var command = command
        do {
            try await command.run()
            XCTFail("Command should throw an error")
        } catch {
            XCTAssertError(error, expectedError.self)
        }
    }
}
