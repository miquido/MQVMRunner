import Foundation

extension AsyncThrowingStream.Continuation where Element == CommandOutput, Failure == Error {
	func fromCommandHandlerEvent(_ commandExecutionEvent: CommandExecutionHandler.Event) {
		switch commandExecutionEvent {
		case .output(let buffer):
			yield(.standardOutput(buffer))
		case .error(let buffer):
			yield(.standardError(buffer))
		case .completed(let exitStatus):
			finish(throwing: ExitStatusError(exitStatus))
		case .failure(let error):
			finish(throwing: error)
		}
	}
}
