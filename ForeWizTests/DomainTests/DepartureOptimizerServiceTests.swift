import Foundation
import Testing
import CoreLocation
@testable import ForeWiz

@MainActor
@Suite("DepartureOptimizerService Tests")
struct DepartureOptimizerServiceTests {
    
    @Test("findOptimalDepartureTime returns result with valid windows")
    func findOptimalDepartureTimeReturnsResultWithValidWindows() async throws {
        let mockWeather = MockWeatherRepository()
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
        let mockWeather = MockWeatherRepository()
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
    
    @Test("DepartureRecommendation display text")
    func departureRecommendationDisplayText() async throws {
        #expect(DepartureRecommendation.optimal.displayText == "Best Time")
        #expect(DepartureRecommendation.good.displayText == "Good Time")
        #expect(DepartureRecommendation.moderate.displayText == "Acceptable")
        #expect(DepartureRecommendation.caution.displayText == "Use Caution")
        #expect(DepartureRecommendation.poor.displayText == "Not Recommended")
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
}
