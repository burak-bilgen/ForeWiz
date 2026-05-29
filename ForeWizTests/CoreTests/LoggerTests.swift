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

    @Test("AppLog measure tracks operation duration")
    func testMeasurePerformance() {
        let result = AppLog.measure(operation: "TestOperation") {
            Thread.sleep(forTimeInterval: 0.01)
            return "success"
        }

        #expect(result == "success")
    }
}
