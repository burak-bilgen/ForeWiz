import Testing
import Foundation
@testable import ForeWiz

@Suite("Performance Utility Tests")
struct PerformanceUtilityTests {

    @Test("AppLog measure tracks synchronous operations")
    func testAppLogMeasureSync() {
        let result = AppLog.measure(operation: "SyncTest") {
            var sum = 0
            for i in 1...100 {
                sum += i
            }
            return sum
        }

        #expect(result == 5050)
    }

    @Test("AppLog measureAsync tracks asynchronous operations")
    func testAppLogMeasureAsync() async {
        let result = await AppLog.measureAsync(operation: "AsyncTest") {
            try? await Task.sleep(nanoseconds: 10_000_000)
            return "async_result"
        }

        #expect(result == "async_result")
    }
}
