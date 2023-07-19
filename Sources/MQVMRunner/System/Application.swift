import AppKit
import Foundation

internal protocol Application {
	var processIdentifier: pid_t { get }
	func terminate() -> Bool
}

extension NSRunningApplication: Application {
}
