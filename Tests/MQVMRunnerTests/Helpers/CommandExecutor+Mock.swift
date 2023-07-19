import Foundation
@testable import MQVMRunner

extension CommandExecutor {
    static func mock(
        defaultResult: String = "result",
        _ handler: @escaping (Command) throws -> Void = { _ in }
    ) -> Self {
        .init(
            execute: handler,
            executeResult: {
                try handler($0)
                return defaultResult
            },
            runDetached: handler
        )
    }
    
    static func mock(
        resultHandler: @escaping (Command) -> String,
        _ handler: @escaping (Command) throws -> Void = { _ in }
    ) -> Self {
        .init(
            execute: handler,
            executeResult: {
                try handler($0)
                return resultHandler($0)
            },
            runDetached: handler
        )
    }
}
