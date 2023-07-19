import ArgumentParser
import Foundation
import MQ

protocol ErrorHandlingParsableCommand: AsyncParsableCommand, LoggerConfigurator {
	mutating func go() async throws
}

extension ErrorHandlingParsableCommand {
	mutating func run() async throws {
		Logger.configure(self)

		do {
			try await go()
		} catch let theError as EmojiableError {
			Logger.error(theError.emoji, theError.displayableString.resolved)
			throw theError
		} catch let theError as TheError {
			Logger.error("🚨", theError.displayableString.resolved)
			throw theError
		} catch {
			Logger.error("🚨", error.localizedDescription)
			throw error
		}
	}
}
