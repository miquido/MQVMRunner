import ArgumentParser
import Foundation
import MQ

@main
internal struct MQVMRunner: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		subcommands: [
			Start.self,
			Execute.self,
			Stop.self,
		]
	)
}
