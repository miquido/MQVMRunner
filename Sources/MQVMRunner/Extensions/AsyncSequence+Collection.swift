import Citadel
import Foundation

extension AsyncSequence {
	func collect() async rethrows -> [Element] {
		try await reduce(into: [Element]()) { $0.append($1) }
	}
}

extension AsyncSequence where Element == ExecCommandOutput {
	func output(
		stdOut: @escaping (String) -> Void,
		stdErr: @escaping (String) -> Void
	) async throws {
		var streamIterator = makeAsyncIterator()
		while let output = try await streamIterator.next() {
			switch output {
			case .stderr(let error):
				stdErr(String(buffer: error))
			case .stdout(let output):
				stdOut(String(buffer: output))
			}
		}
	}

}
