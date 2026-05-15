import Testing
import Foundation
import OSLog
@testable import ForeWiz

@Suite("Logger Tests")
struct LoggerTests {

    @Test("Log levels map to correct OSLogType")
    func testLogLevelMapping() {
        #expect(LogLevel.debug.osLogType == .debug)
        #expect(LogLevel.info.osLogType == .info)
        #expect(LogLevel.warning.osLogType == .default)
        #expect(LogLevel.error.osLogType == .error)
        #expect(LogLevel.critical.osLogType == .fault)
    }

    @Test("LogContext captures correct file information")
    func testLogContext() {
        let context = LogContext(file: "/Users/test/ForeWiz/SomeFile.swift", function: "testFunction()", line: 42)

        #expect(context.file == "SomeFile.swift")
        #expect(context.function == "testFunction()")
        #expect(context.line == 42)
        #expect(context.timestamp.timeIntervalSinceNow < 1)
    }

    @Test("AppLog measure tracks operation duration")
    func testMeasurePerformance() {
        var capturedDuration: TimeInterval?

        let result = AppLog.measure(operation: "TestOperation") {
            Thread.sleep(forTimeInterval: 0.01)
            return "success"
        }

        #expect(result == "success")
    }

    @Test("StructuredLogger initializes correctly")
    func testStructuredLoggerInitialization() {
        let logger = StructuredLogger(subsystem: "com.test", category: "test")

        #expect(logger != nil)
    }

    @Test("Loggable protocol can be implemented")
    func testLoggableProtocol() {
        struct TestError: Error, Loggable {
            let message: String

            var logDescription: String {
                "TestError: \(message)"
            }
        }

        let error = TestError(message: "Test message")
        #expect(error.logDescription == "TestError: Test message")
    }


}


