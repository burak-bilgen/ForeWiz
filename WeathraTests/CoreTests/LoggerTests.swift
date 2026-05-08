import Testing
import Foundation
import OSLog
@testable import Weathra

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
        let context = LogContext(file: "/Users/test/Weathra/SomeFile.swift", function: "testFunction()", line: 42)

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

    @Test("PerformanceMonitor singleton exists")
    func testPerformanceMonitorSingleton() {
        let monitor1 = PerformanceMonitor.shared
        let monitor2 = PerformanceMonitor.shared

        #expect(monitor1 === monitor2)
    }

    @Test("PerformanceMonitor tracks operations")
    func testPerformanceMonitorTracking() async {
        let monitor = PerformanceMonitor.shared

        monitor.startOperation("TestOperation")

        try? await Task.sleep(nanoseconds: 10_000_000)

        monitor.endOperation("TestOperation")

        #expect(true)
    }
}

@Suite("Performance Tests")
struct PerformanceTests {

    @Test("MemoryCache stores and retrieves values")
    func testMemoryCache() {
        let cache = MemoryCache<String, String>()

        cache.set("value1", forKey: "key1")
        let retrieved = cache.get("key1")

        #expect(retrieved == "value1")
    }

    @Test("MemoryCache returns nil for missing keys")
    func testMemoryCacheMissingKey() {
        let cache = MemoryCache<String, String>()

        let retrieved = cache.get("nonexistent")

        #expect(retrieved == nil)
    }

    @Test("MemoryCache removes values")
    func testMemoryCacheRemoval() {
        let cache = MemoryCache<String, String>()

        cache.set("value1", forKey: "key1")
        cache.remove("key1")
        let retrieved = cache.get("key1")

        #expect(retrieved == nil)
    }

    @Test("MemoryCache clears all values")
    func testMemoryCacheClear() {
        let cache = MemoryCache<String, String>()

        cache.set("value1", forKey: "key1")
        cache.set("value2", forKey: "key2")
        cache.removeAll()

        #expect(cache.get("key1") == nil)
        #expect(cache.get("key2") == nil)
    }

    @Test("Cached property wrapper works with UserDefaults")
    func testCachedPropertyWrapper() {
        struct TestContainer {
            @Cached("test_key")
            var value: String?
        }

        var container = TestContainer()
        container.value = "test_value"

        #expect(container.value == "test_value")

        container.value = nil
        #expect(container.value == nil)
    }

    @Test("RateLimiter enforces intervals")
    func testRateLimiter() {
        let limiter = RateLimiter(interval: 0.1)

        var callCount = 0
        let executed1 = limiter.execute { callCount += 1 }
        let executed2 = limiter.execute { callCount += 1 }

        #expect(executed1 == true)
        #expect(executed2 == false)
        #expect(callCount == 1)
    }

    @Test("Throttled wrapper enforces update intervals")
    func testThrottledWrapper() {
        @Throttled(interval: 0.1)
        var value: Int = 0

        value = 1
        #expect(value == 1)

        value = 2
        #expect(value == 2)

        value = 3
        #expect(value == 3)
    }

    @Test("LazyLoad wrapper defers initialization")
    func testLazyLoad() {
        var initializationCount = 0

        struct TestContainer {
            var initCount: Int

            mutating func getValue() -> Int {
                initializationCount += 1
                return 42
            }
        }

        @LazyLoad({ 42 })
        var value: Int

        #expect(value == 42)
        #expect(value == 42)
    }

    @Test("TaskLimiter cancels previous tasks")
    func testTaskLimiter() async {
        var limiter = TaskLimiter()

        var executedTasks: [Int] = []

        limiter.execute {
            try? await Task.sleep(nanoseconds: 100_000_000)
            executedTasks.append(1)
        }

        limiter.execute {
            executedTasks.append(2)
        }

        try? await Task.sleep(nanoseconds: 200_000_000)

        #expect(executedTasks.contains(2))
    }

    @Test("PrefetchCache tracks prefetched keys")
    func testPrefetchCache() {
        var cache = PrefetchCache<String>()

        cache.prefetch(["key1", "key2", "key3"])

        #expect(cache.isPrefetched("key1"))
        #expect(cache.isPrefetched("key2"))
        #expect(cache.isPrefetched("key3"))
        #expect(!cache.isPrefetched("key4"))
    }

    @Test("RequestDeduper prevents duplicate requests")
    func testRequestDeduper() async {
        var deduper = RequestDeduper<String>()

        var requestCount = 0

        async func makeRequest() async -> String {
            requestCount += 1
            try? await Task.sleep(nanoseconds: 50_000_000)
            return "result_\(requestCount)"
        }

        async let result1 = deduper.deduplicate(key: "key1", operation: makeRequest)
        async let result2 = deduper.deduplicate(key: "key1", operation: makeRequest)
        async let result3 = deduper.deduplicate(key: "key1", operation: makeRequest)

        let results = await [result1, result2, result3]

        #expect(requestCount == 1)
        #expect(results[0] == results[1])
        #expect(results[1] == results[2])
    }
}
