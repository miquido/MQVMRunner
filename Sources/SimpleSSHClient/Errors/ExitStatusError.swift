import Foundation

struct ExitStatusError: Error {
	let exitStatus: Int

	init?(_ exitStatus: Int) {
		guard exitStatus != 0 else {
			return nil
		}
		self.exitStatus = exitStatus
	}
}
