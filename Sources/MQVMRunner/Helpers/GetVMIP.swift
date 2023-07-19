import Foundation

internal protocol IPAble {
	var ip: String { get set }
	var timeout: UInt { get }
}

extension IPAble {
	internal mutating func getVMIP(tart: String, image: String) throws {
		Logger.info("🖥️", "Getting VM IP")

		var retry = timeout + 1

		while true {
			retry -= 1

			do {
				let output = try Command(tart, "ip", image)
					.executeResult()
					.trimmingCharacters(in: .whitespacesAndNewlines)

				guard !output.isEmpty else {
					throw GetIPEmpty.error()
				}

				ip = output

				return
			} catch {
				if retry == 0 {
					throw error
				}
			}
			sleep(1)
		}
	}
}
