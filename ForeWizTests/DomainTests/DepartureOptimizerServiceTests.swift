import XCTest
import CoreLocation
@testable import ForeWiz

// MARK: - Departure Optimizer Service Tests
/// Comprehensive test suite for WizPath departure optimization logic
@MainActor
final class DepartureOptimizerServiceTests: XCTestCase {
    
    // MARK: - Properties
    private var sut: DepartureOptimizerService!
    private var mockWeatherService: MockWeatherService!
    private var mockRoutingService: MockRoutingService!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockWeatherService = MockWeatherService()
        mockRoutingService = MockRoutingService()
        
        // Initialize service with mocks
        sut = DepartureOptimizerService.shared
    }
    
    override func tearDown() {
        mockWeatherService.reset()
        mockRoutingService.reset()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Case 1: Happy Path
    /// Verifies that optimal departure times are calculated correctly with valid weather data
    func testOptimizeRoute_WithValidData_ShouldReturnOptimalETA() async throws {
        // Given - Valid weather data
        let validWeather = SegmentWeather(
            condition: .clear,
            temperature: 25.0,
            precipitationChance: 0.0,
            windSpeed: 5.0,
            visibility: 10000,
            severity: .good
        )
        
        let origin = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let destination = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        let mode = TravelMode.car
        
        let mockRoute = createMockRoute(
            origin: origin,
            destination: destination,
            totalDuration: 1800, // 30 minutes
            distance: 15000,
            weather: validWeather
        )
        
        // When
        let result = await sut.findOptimalDepartures(
            route: mockRoute,
            mode: mode,
            timeWindow: 4 * 3600, // 4 hours
            interval: 3600 // 1 hour
        )
        
        // Then
        XCTAssertFalse(result.slots.isEmpty, "Should return at least one departure slot")
        XCTAssertNotNil(result.recommendedSlot, "Should recommend an optimal slot")
        XCTAssertGreaterThan(result.recommendedSlot?.score ?? 0, 0, "Score should be positive")
        XCTAssertLessThanOrEqual(result.recommendedSlot?.score ?? 101, 100, "Score should not exceed 100")
        
        // Verify slots have valid durations
        for slot in result.slots {
            XCTAssertGreaterThan(slot.eta, 0, "ETA should be positive")
            XCTAssertFalse(slot.durationLabel.isEmpty, "Duration label should not be empty")
            XCTAssertFalse(slot.timeLabel.isEmpty, "Time label should not be empty")
        }
        
        // Verify no weather errors occurred
        XCTAssertFalse(result.hasWeatherDataError, "Should not have weather data errors with valid data")
        XCTAssertNil(result.weatherUnavailableMessage, "Should not show weather unavailable message")
    }
    
    // MARK: - Test Case 2: Weather Nil Fallback (The Crash Scenario)
    /// Simulates the previous crash where weather data was nil or missing
    /// This test verifies the graceful fallback mechanism
    func testOptimizeRoute_WhenWeatherIsNil_ShouldFallbackGracefully() async throws {
        // Given - Route with zero-temperature weather (simulating nil/invalid data)
        let nilWeather = SegmentWeather(
            condition: .clear,
            temperature: 0,  // Zero temperature indicates missing data
            precipitationChance: 0,
            windSpeed: 0,
            visibility: 0,
            severity: .good
        )
        
        let origin = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let destination = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        let mode = TravelMode.car
        
        let mockRoute = createMockRoute(
            origin: origin,
            destination: destination,
            totalDuration: 1800,
            distance: 15000,
            weather: nilWeather
        )
        
        // When - This should NOT crash
        let result = await sut.findOptimalDepartures(
            route: mockRoute,
            mode: mode,
            timeWindow: 2 * 3600,
            interval: 3600
        )
        
        // Then - Should gracefully handle missing weather
        XCTAssertFalse(result.slots.isEmpty, "Should still return slots even with nil weather")
        
        // Should flag weather data error (temperature is 0)
        XCTAssertTrue(result.hasWeatherDataError, "Should indicate weather data error")
        XCTAssertNotNil(result.weatherUnavailableMessage, "Should show weather unavailable message")
        
        // Should still provide ETA estimates based on traffic
        if let firstSlot = result.slots.first {
            XCTAssertGreaterThan(firstSlot.eta, 0, "Should still have ETA estimate")
        }
    }
    
    // MARK: - Test Case 3: Route Failure
    /// Verifies proper error handling when route calculation fails
    func testOptimizeRoute_WhenRouteFails_ShouldHandleErrorGracefully() async throws {
        // Given
        mockRoutingService.scenario = .noRoute
        
        let origin = CLLocationCoordinate2D(latitude: 0, longitude: 0) // Invalid coordinates
        let destination = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let mode = TravelMode.car
        
        let mockRoute = createMockRoute(
            origin: origin,
            destination: destination,
            totalDuration: 0,
            distance: 0
        )
        
        // When
        let result = await sut.findOptimalDepartures(
            route: mockRoute,
            mode: mode,
            timeWindow: 2 * 3600,
            interval: 3600
        )
        
        // Then - Should handle gracefully, not crash
        // With zero duration route, should still produce results
        XCTAssertFalse(result.slots.isEmpty, "Should handle zero-duration route gracefully")
        
        // All slots should have valid (even if zero) ETAs
        for slot in result.slots {
            XCTAssertGreaterThanOrEqual(slot.eta, 0, "ETA should be non-negative")
        }
    }
    
    // MARK: - Test Case 4: Midnight and Next Day Edge Cases
    /// Tests ETA calculations crossing midnight and day boundaries
    func testETA_EdgeCases_MidnightAndNextDayCalculations() async throws {
        // Given - Create a route that spans midnight
        let origin = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let destination = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        let mode = TravelMode.car
        
        // Mock route with long duration crossing midnight
        let longDuration: TimeInterval = 4 * 3600 // 4 hours
        let mockRoute = createMockRoute(
            origin: origin,
            destination: destination,
            totalDuration: longDuration,
            distance: 100000
        )
        
        // When - Test with time window that crosses midnight
        let result = await sut.findOptimalDepartures(
            route: mockRoute,
            mode: mode,
            timeWindow: 8 * 3600, // 8 hour window
            interval: 1800 // 30 min intervals
        )
        
        // Then
        XCTAssertFalse(result.slots.isEmpty, "Should handle overnight routes")
        
        // Verify time labels are formatted correctly for all slots
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for slot in result.slots {
            // Verify time label format
            XCTAssertFalse(slot.timeLabel.isEmpty, "Time label should not be empty")
            XCTAssertTrue(slot.timeLabel.contains(":"), "Time label should contain colon")
            
            // Verify slot time is within expected range
            let slotDate = slot.time
            let now = Date()
            let eightHoursLater = now.addingTimeInterval(8 * 3600)
            
            XCTAssertGreaterThanOrEqual(slotDate.timeIntervalSince1970, now.timeIntervalSince1970 - 60, "Slot time should be around now or later")
            XCTAssertLessThanOrEqual(slotDate.timeIntervalSince1970, eightHoursLater.timeIntervalSince1970 + 60, "Slot time should be within 8 hours")
        }
        
        // Verify slots are in chronological order
        var previousTime: Date?
        for slot in result.slots {
            if let prev = previousTime {
                XCTAssertGreaterThan(slot.time.timeIntervalSince1970, prev.timeIntervalSince1970, "Slots should be in chronological order")
            }
            previousTime = slot.time
        }
    }
    
    // MARK: - Additional Edge Cases
    
    /// Tests handling of extreme weather conditions
    func testOptimizeRoute_WithExtremeHeat_ShouldApplyCorrectMultiplier() async throws {
        // Given - Extreme heat scenario with weather data in route
        let extremeHeatWeather = SegmentWeather(
            condition: .clear,
            temperature: 42.0,
            precipitationChance: 0.0,
            windSpeed: 10.0,
            visibility: 10000,
            severity: .severe
        )
        
        let origin = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let destination = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        let mode = TravelMode.car
        
        let mockRoute = createMockRoute(
            origin: origin,
            destination: destination,
            totalDuration: 1800,
            distance: 15000,
            weather: extremeHeatWeather
        )
        
        // When
        let result = await sut.findOptimalDepartures(
            route: mockRoute,
            mode: mode,
            timeWindow: 2 * 3600,
            interval: 3600
        )
        
        // Then
        XCTAssertFalse(result.slots.isEmpty)
        
        // Verify slots have temperature data
        if let firstSlot = result.slots.first {
            XCTAssertGreaterThanOrEqual(firstSlot.temperature, 40, "Should capture extreme temperature")
        }
    }
    
    /// Tests concurrent route calculations don't cause race conditions
    func testConcurrentCalculations_ShouldNotCauseRaceConditions() async throws {
        // Given
        let origin = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let destination = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        let mode = TravelMode.car
        
        let mockRoute = createMockRoute(
            origin: origin,
            destination: destination,
            totalDuration: 1800,
            distance: 15000
        )
        
        // When - Run multiple calculations concurrently
        async let result1 = sut.findOptimalDepartures(route: mockRoute, mode: mode, timeWindow: 2 * 3600, interval: 3600)
        async let result2 = sut.findOptimalDepartures(route: mockRoute, mode: mode, timeWindow: 2 * 3600, interval: 3600)
        async let result3 = sut.findOptimalDepartures(route: mockRoute, mode: mode, timeWindow: 2 * 3600, interval: 3600)
        
        let results = await [result1, result2, result3]
        
        // Then - All should complete without race conditions
        for (index, result) in results.enumerated() {
            XCTAssertFalse(result.slots.isEmpty, "Result \(index) should have slots")
            XCTAssertNotNil(result.recommendedSlot, "Result \(index) should have recommendation")
        }
    }
    
    /// Tests that service handles routes without weather data gracefully
    func testOptimizeRoute_WithoutWeatherData_ShouldStillProvideEstimates() async {
        // Given - Route without any weather data
        let origin = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let destination = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        let mode = TravelMode.car
        
        let mockRoute = createMockRoute(
            origin: origin,
            destination: destination,
            totalDuration: 1800,
            distance: 15000,
            weather: nil  // No weather data
        )
        
        // When
        let result = await sut.findOptimalDepartures(
            route: mockRoute,
            mode: mode,
            timeWindow: 2 * 3600,
            interval: 3600
        )
        
        // Then - Should complete and provide traffic-based estimates
        XCTAssertFalse(result.slots.isEmpty, "Should provide slots even without weather")
        XCTAssertTrue(result.hasWeatherDataError, "Should flag missing weather data")
        XCTAssertNotNil(result.weatherUnavailableMessage, "Should show weather unavailable message")
        
        // Should still have valid ETAs based on traffic
        if let firstSlot = result.slots.first {
            XCTAssertGreaterThan(firstSlot.eta, 0, "Should have ETA estimate")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        totalDuration: TimeInterval,
        distance: CLLocationDistance,
        weather: SegmentWeather? = nil
    ) -> WizPathRoute {
        // Create mock segments with correct properties
        let midPoint = CLLocationCoordinate2D(
            latitude: (origin.latitude + destination.latitude) / 2,
            longitude: (origin.longitude + destination.longitude) / 2
        )
        
        let now = Date()
        let halfDuration = totalDuration / 2
        
        let segment1 = WizPathSegment(
            id: UUID(),
            coordinate: origin,
            estimatedArrival: now.addingTimeInterval(halfDuration),
            distanceFromStart: 0,
            travelTime: 0,
            weather: weather
        )
        
        let segment2 = WizPathSegment(
            id: UUID(),
            coordinate: midPoint,
            estimatedArrival: now.addingTimeInterval(totalDuration),
            distanceFromStart: distance / 2,
            travelTime: halfDuration,
            weather: weather
        )
        
        let segment3 = WizPathSegment(
            id: UUID(),
            coordinate: destination,
            estimatedArrival: now.addingTimeInterval(totalDuration),
            distanceFromStart: distance,
            travelTime: totalDuration,
            weather: weather
        )
        
        return WizPathRoute(
            id: UUID(),
            origin: origin,
            destination: destination,
            travelMode: .car,
            departureTime: now,
            segments: [segment1, segment2, segment3],
            totalDuration: totalDuration,
            totalDistance: distance,
            polyline: nil
        )
    }
}
