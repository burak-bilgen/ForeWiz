import Testing
import Foundation
import SwiftUI
@testable import Weathra

@Suite("Performance Utility Tests")
struct PerformanceUtilityTests {

    @Test("PerformanceMonitor measures operation duration")
    func testPerformanceMeasurement() async {
        let monitor = PerformanceMonitor.shared

        let startTime = CFAbsoluteTimeGetCurrent()
        monitor.startOperation("TestOperation")

        try? await Task.sleep(nanoseconds: 100_000_000)

        monitor.endOperation("TestOperation")
        let endTime = CFAbsoluteTimeGetCurrent()

        let duration = endTime - startTime
        #expect(duration >= 0.1)
    }

    @Test("MemoryCache stores and retrieves values correctly")
    func testMemoryCacheBasicOperations() {
        let cache = MemoryCache<String, Int>()

        cache.set(42, forKey: "test_key")
        let value = cache.get("test_key")

        #expect(value == 42)
    }

    @Test("MemoryCache returns nil for missing keys")
    func testMemoryCacheMissingKey() {
        let cache = MemoryCache<String, String>()

        let value = cache.get("nonexistent_key")

        #expect(value == nil)
    }

    @Test("MemoryCache removes values correctly")
    func testMemoryCacheRemoval() {
        let cache = MemoryCache<String, String>()

        cache.set("value", forKey: "key")
        cache.remove("key")
        let value = cache.get("key")

        #expect(value == nil)
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

    @Test("RateLimiter enforces time intervals")
    func testRateLimiter() {
        let limiter = RateLimiter(interval: 0.1)

        var callCount = 0
        let executed1 = limiter.execute { callCount += 1 }
        let executed2 = limiter.execute { callCount += 1 }

        #expect(executed1 == true)
        #expect(executed2 == false)
        #expect(callCount == 1)
    }

    @Test("Throttled wrapper limits updates")
    func testThrottledWrapper() {
        @Throttled(interval: 0.05)
        var value: Int = 0

        value = 1
        #expect(value == 1)

        value = 2
        #expect(value == 1)
    }

    @Test("LazyLoad defers initialization")
    func testLazyLoad() {
        var initCount = 0

        @LazyLoad({
            initCount += 1
            return "initialized"
        })
        var value: String

        #expect(initCount == 0)
        _ = value
        #expect(initCount == 1)
        _ = value
        #expect(initCount == 1)
    }

    @Test("TaskLimiter cancels previous tasks")
    func testTaskLimiter() async {
        var limiter = TaskLimiter()

        var executedTasks: [Int] = []

        limiter.execute {
            try? await Task.sleep(nanoseconds: 50_000_000)
            executedTasks.append(1)
        }

        limiter.execute {
            executedTasks.append(2)
        }

        try? await Task.sleep(nanoseconds: 150_000_000)

        #expect(executedTasks.contains(2))
    }

    @Test("PrefetchCache tracks prefetched items")
    func testPrefetchCache() {
        var cache = PrefetchCache<String>()

        cache.prefetch(["item1", "item2", "item3"])

        #expect(cache.isPrefetched("item1"))
        #expect(cache.isPrefetched("item2"))
        #expect(cache.isPrefetched("item3"))
        #expect(!cache.isPrefetched("item4"))
    }

    @Test("RequestDeduper prevents duplicate concurrent requests")
    func testRequestDeduper() async throws {
        let deduper = RequestDeduper<String>()
        let counter = PerformanceRequestCounter()

        @Sendable func makeRequest() async throws -> String {
            await counter.increment()
            try? await Task.sleep(nanoseconds: 10_000_000)
            return "result"
        }

        async let result1 = deduper.deduplicate(key: "key", operation: makeRequest)
        async let result2 = deduper.deduplicate(key: "key", operation: makeRequest)
        async let result3 = deduper.deduplicate(key: "key", operation: makeRequest)

        let results = try await [result1, result2, result3]

        #expect(await counter.value == 1)
        #expect(results.allSatisfy { $0 == "result" })
    }

    @Test("Cached property wrapper stores and retrieves values")
    func testCachedPropertyWrapper() {
        struct TestContainer {
            @Cached("test_cached_key")
            var value: String?
        }

        var container = TestContainer()

        container.value = "cached_value"
        #expect(container.value == "cached_value")

        container.value = nil
        #expect(container.value == nil)
    }

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

@Suite("Background Refresh Tests")
struct BackgroundRefreshTests {

    @Test("AppLifecycleManager singleton exists")
    func testAppLifecycleManagerSingleton() {
        let manager1 = AppLifecycleManager.shared
        let manager2 = AppLifecycleManager.shared

        #expect(manager1 === manager2)
    }

    @Test("RefreshController singleton exists")
    func testRefreshControllerSingleton() {
        let controller1 = RefreshController.shared
        let controller2 = RefreshController.shared

        #expect(controller1 === controller2)
    }

    @Test("NetworkConnectivityMonitor singleton exists")
    func testNetworkConnectivityMonitorSingleton() {
        let monitor1 = NetworkConnectivityMonitor.shared
        let monitor2 = NetworkConnectivityMonitor.shared

        #expect(monitor1 === monitor2)
    }

    @Test("BatteryAwareRefreshManager singleton exists")
    func testBatteryAwareRefreshManagerSingleton() {
        let manager1 = BatteryAwareRefreshManager.shared
        let manager2 = BatteryAwareRefreshManager.shared

        #expect(manager1 === manager2)
    }

    @Test("RefreshController timeUntilNextRefresh is non-negative")
    func testTimeUntilNextRefresh() {
        let controller = RefreshController.shared
        let timeRemaining = controller.timeUntilNextRefresh

        #expect(timeRemaining >= 0)
    }
}

@Suite("Accessibility Helper Tests")
struct AccessibilityHelperTests {

    @Test("AccessibleModifier creates correct accessibility configuration")
    func testAccessibleModifier() {
        let modifier = AccessibleModifier(
            label: "Test Label",
            hint: "Test Hint",
            traits: .isButton,
            sortPriority: 10,
            hidden: false
        )

        #expect(modifier.label == "Test Label")
        #expect(modifier.hint == "Test Hint")
        #expect(modifier.sortPriority == 10)
        #expect(modifier.hidden == false)
    }

    @Test("AccessibleButton creates button with correct traits")
    func testAccessibleButton() {
        let button = Text("Test")
            .accessibleButton(label: "Test Button", hint: "Tap to test")

        #expect(button != nil)
    }

    @Test("AccessibleHeader creates header with correct traits")
    func testAccessibleHeader() {
        let header = Text("Test Header")
            .accessibleHeader(label: "Test Header")

        #expect(header != nil)
    }

    @Test("ComfortLevel enum has correct values")
    func testComfortLevel() {
        let levels: [ComfortLevel] = [.excellent, .good, .moderate, .poor]

        #expect(levels.count == 4)
    }

    @Test("Trend enum has correct values")
    func testTrend() {
        let trends: [Trend] = [.rising, .falling, .stable]

        #expect(trends.count == 3)
    }
}

@Suite("Animation Tests")
struct AnimationTests {

    @Test("Particle struct initialization")
    func testParticleStruct() {
        let particle = Particle(
            x: 0.5,
            y: 0.5,
            size: 5.0,
            opacity: 0.8,
            speedX: 0.01,
            speedY: 0.01
        )

        #expect(particle.x == 0.5)
        #expect(particle.y == 0.5)
        #expect(particle.size == 5.0)
        #expect(particle.opacity == 0.8)
    }

    @Test("ConfettiPiece struct initialization")
    func testConfettiPiece() {
        let piece = ConfettiPiece(
            x: 100.0,
            y: 50.0,
            size: 10.0,
            color: .red,
            rotation: 0.5,
            velocity: 3.0,
            rotationSpeed: 0.1
        )

        #expect(piece.x == 100.0)
        #expect(piece.y == 50.0)
        #expect(piece.size == 10.0)
    }

    @Test("ChartDataPoint struct initialization")
    func testChartDataPoint() {
        let point = ChartDataPoint(hour: 12, value: 25.5, index: 0)

        #expect(point.hour == 12)
        #expect(point.value == 25.5)
        #expect(point.index == 0)
    }

    @Test("ComfortWindow struct initialization")
    func testComfortWindow() {
        let window = ComfortWindow(
            startHour: 8,
            endHour: 12,
            score: 85,
            level: .good
        )

        #expect(window.startHour == 8)
        #expect(window.endHour == 12)
        #expect(window.score == 85)
    }
}

@Suite("Siri Shortcuts Tests")
struct SiriShortcutsTests {

    @Test("MetricType enum has correct cases")
    func testMetricType() {
        let types: [MetricType] = [.temperature, .humidity, .wind, .uvIndex, .precipitation]

        #expect(types.count == 5)
    }

    @Test("TimeRange enum has correct cases")
    func testTimeRange() {
        let ranges: [TimeRange] = [.today, .next24Hours, .tomorrow]

        #expect(ranges.count == 3)
    }

    @Test("ContainerProvider singleton exists")
    @MainActor
    func testContainerProviderSingleton() {
        let provider1 = ContainerProvider.shared
        let provider2 = ContainerProvider.shared

        #expect(provider1 === provider2)
    }
}

private actor PerformanceRequestCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}
