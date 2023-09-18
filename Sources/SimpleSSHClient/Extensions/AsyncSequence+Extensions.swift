import Foundation

extension AsyncSequence where Element == CommandOutput {
	public func output(
		stdOut: @escaping (String) -> Void,
		stdErr: @escaping (String) -> Void
	) async throws {
		var streamIterator = makeAsyncIterator()
		while let output = try await streamIterator.next() {
			switch output {
			case .standardError(let error):
				stdErr(String(buffer: error))
			case .standardOutput(let output):
				stdOut(String(buffer: output))
			}
		}
	}

	public func waitToFinish() async throws {
		var iterator = makeAsyncIterator()
		while let _ = try await iterator.next() {
			/** no-op */
		}
	}
}
