import AppKit
import Foundation

internal struct ApplicationSystem {
	internal static var current: ApplicationSystem = .default

	internal let apllicationWithPid: (pid_t) -> Application?
}

extension ApplicationSystem {
	internal static var `default`: Self {
		func apllication(pid: pid_t) -> Application? {
			NSWorkspace.shared.runningApplications.first { app in
				app.processIdentifier == pid
			}
		}

		return .init(
			apllicationWithPid: apllication(pid:)
		)
	}
}
