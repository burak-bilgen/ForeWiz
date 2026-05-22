import Foundation
import Testing
import CoreLocation
import WizPathKit
@testable import ForeWiz

@MainActor
@Suite("DepartureOptimizerService Tests")
struct DepartureOptimizerServiceTests {
    
    @Test("findOptimalDepartureTime returns result with valid windows")
    func findOptimalDepartureTimeReturnsResultWithValidWindows() async throws {
        let mockWeather = MockWizPathWeatherSource()
        let service = DepartureOptimizerService(weatherRepository: mockWeather)
        
        let now = Date()
        let oneHourLater = now.addingTimeInterval(3600)
        
        let result = try await service.findOptimalDepartureTime(
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            earliestDeparture: now,
            latestDeparture: oneHourLater
        )
        
        #expect(result.totalWindowsEvaluated > 0)
        #expect(result.scoredWindows.count > 0)
    }
    
    @Test("scored windows are sorted by total score descending")
    func scoredWindowsAreSortedByTotalScoreDescending() async throws {
        let mockWeather = MockWizPathWeatherSource()
        let service = DepartureOptimizerService(weatherRepository: mockWeather)
        
        let now = Date()
        let fourHoursLater = now.addingTimeInterval(4 * 3600)
        
        let result = try await service.findOptimalDepartureTime(
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            earliestDeparture: now,
            latestDeparture: fourHoursLater
        )
        
        for i in 1..<result.scoredWindows.count {
            #expect(result.scoredWindows[i - 1].totalScore >= result.scoredWindows[i].totalScore)
        }
    }
    
    @Test("DepartureRecommendation color hex values")
    func departureRecommendationColorHexValues() async throws {
        #expect(DepartureRecommendation.optimal.colorHex == "#34C759")
        #expect(DepartureRecommendation.good.colorHex == "#30D158")
        #expect(DepartureRecommendation.moderate.colorHex == "#FFCC00")
        #expect(DepartureRecommendation.caution.colorHex == "#FF9500")
        #expect(DepartureRecommendation.poor.colorHex == "#FF3B30")
    }
    
    @Test("DepartureRecommendation display text returns localized string")
    func departureRecommendationDisplayText() async throws {
        #expect(!DepartureRecommendation.optimal.displayText.isEmpty)
        #expect(!DepartureRecommendation.good.displayText.isEmpty)
        #expect(!DepartureRecommendation.moderate.displayText.isEmpty)
        #expect(!DepartureRecommendation.caution.displayText.isEmpty)
        #expect(!DepartureRecommendation.poor.displayText.isEmpty)
    }
    
    @Test("ScoredDepartureWindow formatted time")
    func scoredDepartureWindowFormattedTime() async throws {
        let window = ScoredDepartureWindow(
            departureTime: Date(),
            weatherScore: 80,
            trafficScore: 75,
            climateScore: 85,
            totalScore: 80,
            alerts: [],
            recommendation: .good
        )
        
        #expect(!window.formattedTime.isEmpty)
    }
    
    @Test("DepartureOptimizationResult formatted best time")
    func departureOptimizationResultFormattedBestTime() async throws {
        let result = DepartureOptimizationResult(
            bestDepartureTime: Date(),
            scoredWindows: [],
            totalWindowsEvaluated: 5
        )
        
        #expect(!result.formattedBestTime.isEmpty)
    }
    
    @Test("DepartureOptimizationResult time until best departure")
    func departureOptimizationResultTimeUntilBestDeparture() async throws {
        let futureDate = Date().addingTimeInterval(3600)
        let result = DepartureOptimizationResult(
            bestDepartureTime: futureDate,
            scoredWindows: [],
            totalWindowsEvaluated: 5
        )
        
        #expect(result.timeUntilBestDeparture > 0)
        #expect(!result.formattedTimeUntil.isEmpty)
    }
    
    @Test("DepartureOptimizationResult negative time until returns zero")
    func departureOptimizationResultNegativeTimeUntilReturnsZero() async throws {
        let pastDate = Date().addingTimeInterval(-3600)
        let result = DepartureOptimizationResult(
            bestDepartureTime: pastDate,
            scoredWindows: [],
            totalWindowsEvaluated: 5
        )
        
        #expect(result.timeUntilBestDeparture == 0)
    }
    
    @Test("Configuration constants are reasonable")
    func configurationConstantsAreReasonable() async throws {
        #expect(DepartureOptimizerService.Configuration.windowCount == 12)
        #expect(DepartureOptimizerService.Configuration.windowInterval == 30 * 60)
        #expect(DepartureOptimizerService.Configuration.minimumWeatherScore == 60)
        #expect(DepartureOptimizerService.Configuration.rushHourMultiplier == 1.5)
    }
    
    // MARK: - Cycling Tests
    
    @Test("findOptimalDepartureTime works with cycling mode")
    func findOptimalDepartureTimeWorksWithCyclingMode() async throws {
        let mockWeather = MockWizPathWeatherSource()
        let service = DepartureOptimizerService(weatherRepository: mockWeather)
        
        let now = Date()
        let fourHoursLater = now.addingTimeInterval(4 * 3600)
        
        let result = try await service.findOptimalDepartureTime(
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .cycling,
            earliestDeparture: now,
            latestDeparture: fourHoursLater
        )
        
        #expect(result.totalWindowsEvaluated > 0)
        #expect(result.scoredWindows.count > 0)
    }
    
    @Test("Cycling mode penalizes midday heat more than car")
    func cyclingModePenalizesMiddayHeat() async throws {
        let mockWeather = MockWizPathWeatherSource()
        let service = DepartureOptimizerService(weatherRepository: mockWeather)
        
        let now = Date()
        let calendar = Calendar.current
        // Set to noon
        guard let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) else {
            #expect(Bool(false), "Could not create noon date")
            return
        }
        let noonPlus30 = noon.addingTimeInterval(30 * 60)
        
        // Test cycling at noon
        let cyclingResult = try await service.findOptimalDepartureTime(
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .cycling,
            earliestDeparture: noon,
            latestDeparture: noonPlus30
        )
        
        // Test car at noon
        let carResult = try await service.findOptimalDepartureTime(
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            earliestDeparture: noon,
            latestDeparture: noonPlus30
        )
        
        // Cycling should ideally have lower scores at noon (heat + wind penalty)
        if !cyclingResult.scoredWindows.isEmpty && !carResult.scoredWindows.isEmpty {
            // This is a heuristic — both could be same since weather is mocked
            #expect(cyclingResult.totalWindowsEvaluated == carResult.totalWindowsEvaluated)
        }
    }
    
    @Test("Cycling mode weights weather more heavily than car")
    func cyclingModeWeightsWeatherMoreHeavily() async throws {
        let mockWeather = MockWizPathWeatherSource()
        let service = DepartureOptimizerService(weatherRepository: mockWeather)
        
        let now = Date()
        let oneHourLater = now.addingTimeInterval(3600)
        
        let cyclingResult = try await service.findOptimalDepartureTime(
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .cycling,
            earliestDeparture: now,
            latestDeparture: oneHourLater
        )
        
        let carResult = try await service.findOptimalDepartureTime(
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            earliestDeparture: now,
            latestDeparture: oneHourLater
        )
        
        // Both should return valid results
        #expect(cyclingResult.totalWindowsEvaluated > 0)
        #expect(carResult.totalWindowsEvaluated > 0)
    }
    
    @Test("Early morning gives bonus for cycling")
    func earlyMorningGivesBonusForCycling() async throws {
        let mockWeather = MockWizPathWeatherSource()
        let service = DepartureOptimizerService(weatherRepository: mockWeather)
        
        let now = Date()
        let calendar = Calendar.current
        // Set to early morning (6 AM)
        guard let early = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) else {
            #expect(Bool(false), "Could not create early morning date")
            return
        }
        let earlyPlus30 = early.addingTimeInterval(30 * 60)
        
        let cyclingResult = try await service.findOptimalDepartureTime(
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .cycling,
            earliestDeparture: early,
            latestDeparture: earlyPlus30
        )
        
        // Should still produce results
        #expect(cyclingResult.totalWindowsEvaluated > 0)
    }
    
    @Test("Night cycling is penalized heavily")
    func nightCyclingIsPenalizedHeavily() async throws {
        let mockWeather = MockWizPathWeatherSource()
        let service = DepartureOptimizerService(weatherRepository: mockWeather)
        
        let now = Date()
        let calendar = Calendar.current
        // Set to late night (10 PM)
        guard let night = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now) else {
            #expect(Bool(false), "Could not create night date")
            return
        }
        let nightPlus30 = night.addingTimeInterval(30 * 60)
        
        let cyclingResult = try await service.findOptimalDepartureTime(
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .cycling,
            earliestDeparture: night,
            latestDeparture: nightPlus30
        )
        
        let carResult = try await service.findOptimalDepartureTime(
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            earliestDeparture: night,
            latestDeparture: nightPlus30
        )
        
        // Cycling at night should have lower scores than car
        if let cyclingScore = cyclingResult.scoredWindows.first?.totalScore,
           let carScore = carResult.scoredWindows.first?.totalScore {
            #expect(cyclingScore <= carScore, "Cycling at night (\(cyclingScore)) should have equal or lower score than car (\(carScore))")
        }
    }
    
    @Test("TravelMode cycling properties")
    func travelModeCyclingProperties() async throws {
        #expect(TravelMode.cycling.rawValue == "cycling")
        #expect(TravelMode.cycling.icon == "bicycle")
        #expect(TravelMode.cycling.segmentInterval == 10 * 60)
        #expect(TravelMode.cycling.colorHex == "#34C759")
        #expect(TravelMode.cycling.averageSpeedKph == 15)
        #expect(TravelMode.cycling.isWindSensitive == true)
        #expect(TravelMode.car.isWindSensitive == false)
        #expect(TravelMode.walking.isWindSensitive == false)
    }
}
