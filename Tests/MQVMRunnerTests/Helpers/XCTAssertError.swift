import XCTest
import MQ
@testable import MQVMRunner

func XCTAssertError<T>(
    _ error: Error,
    _ t: T.Type,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertTrue(error.verify(t), "\(error) is not an instance of \(t)", file: file, line: line)
}

extension Error {
    fileprivate func verify<T>(_ t: T.Type) -> Bool {
        switch self {
        case let error as Unidentified:
            return error.underlyingError.verify(t)
        case let error as ManyErrors:
            return error.errors.contains { error in
                error.verify(t)
            }
        default:
            return self is T
        }
    }
}
