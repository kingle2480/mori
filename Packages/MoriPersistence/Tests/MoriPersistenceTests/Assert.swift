import Foundation

nonisolated(unsafe) var testCount = 0
nonisolated(unsafe) var failCount = 0

func assert(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    testCount += 1
    if !condition {
        failCount += 1
        fputs("  FAIL [\(file):\(line)] \(message)\n", stderr)
    }
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", file: String = #file, line: Int = #line) {
    testCount += 1
    if a != b {
        failCount += 1
        fputs("  FAIL [\(file):\(line)] Expected \(a) == \(b). \(message)\n", stderr)
    }
}

func assertNotEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", file: String = #file, line: Int = #line) {
    testCount += 1
    if a == b {
        failCount += 1
        fputs("  FAIL [\(file):\(line)] Expected \(a) != \(b). \(message)\n", stderr)
    }
}

func assertNil<T>(_ value: T?, _ message: String = "", file: String = #file, line: Int = #line) {
    testCount += 1
    if value != nil {
        failCount += 1
        fputs("  FAIL [\(file):\(line)] Expected nil. \(message)\n", stderr)
    }
}

func assertNotNil<T>(_ value: T?, _ message: String = "", file: String = #file, line: Int = #line) {
    testCount += 1
    if value == nil {
        failCount += 1
        fputs("  FAIL [\(file):\(line)] Expected non-nil. \(message)\n", stderr)
    }
}

func assertTrue(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    assert(condition, message, file: file, line: line)
}

func assertFalse(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    assert(!condition, message, file: file, line: line)
}

func printResults() {
    if failCount == 0 {
        print("All \(testCount) assertions passed.")
    } else {
        print("\(failCount)/\(testCount) assertions FAILED.")
    }
}
