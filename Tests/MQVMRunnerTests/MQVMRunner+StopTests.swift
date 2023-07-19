import XCTest
import ArgumentParser
@testable import MQVMRunner

final class MQVMRunnerStopTests: XCTestCase {
    func testExecute() async throws {
        let stopExpectation = expectation(description: "Command should stop the VM")
        let deleteExpectation = expectation(description: "Command should delete the image")
        
        var command = command(executor: .mock({
            if $0.command.hasSuffix("tart"), $0.string.contains("stop") {
                stopExpectation.fulfill()
            }
            if $0.command.hasSuffix("tart"), $0.string.contains("delete") {
                deleteExpectation.fulfill()
            }
        }))
        
        try await command.run()
        
        await fulfillment(of: [stopExpectation, deleteExpectation], timeout: 0)
    }
    
    func testStopFail() async throws {
        let command = command(executor: .mock({
            if $0.command.hasSuffix("tart"), $0.string.contains("stop") {
                throw StopError()
            }
        }))
        await checkForError(in: command, expectedError: StopError.self)
    }
    
    func testPsAuxFail() async throws {
        let command = command(executor: .mock({
            if $0.command.hasSuffix("tart"), $0.string.contains("stop") {
                throw StopError()
            }
            if $0.command.hasSuffix("ps"), $0.string.contains("aux") {
                throw PsAuxError()
            }
        }))
        await checkForError(in: command, expectedError: PsAuxError.self)
    }
    
    func testDeleteFail() async throws {
        let command = command(executor: .mock({
            if $0.command.hasSuffix("tart"), $0.string.contains("delete") {
                throw DeleteError()
            }
        }))
        await checkForError(in: command, expectedError: DeleteError.self)
    }
}

extension MQVMRunnerStopTests {
    private func command(executor: CommandExecutor) -> AsyncParsableCommand {
        CommandExecutor.current = executor
        
        var command = Stop()
        
        command.jobID = "job"
        command.tart = "tart"
        command.verbose = true
        command.colorsDisable = true
        command.emojiDisable = true
        
        return command
    }
    
    private struct StopError: Error {}
    private struct PsAuxError: Error {}
    private struct DeleteError: Error {}
}
