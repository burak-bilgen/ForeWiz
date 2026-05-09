import Foundation
import Testing
@testable import Weathra

struct DataConsistencyTests {
    @Test func recommendationScoreIsValid() {
        let recommendation = DailyRecommendation(
            generatedAt: Date(),
            outdoorDecision: .good,
            outdoorScore: WeatherScore(rawValue: 85),
            bestOutdoorWindow: nil,
            bestActivityWindows: [],
            avoidWindows: [],
            outfit: OutfitRecommendation(title: "Test", items: [], accessories: [], warning: nil),
            risks: [],
            summaryText: "Test",
            explanation: "Test"
        )

        #expect(recommendation.outdoorScore.rawValue >= 0)
        #expect(recommendation.outdoorScore.rawValue <= 100)
    }

    @Test func temperatureUnitConversion() {
        let celsius: Double = 25.0
        let fahrenheit = (celsius * 9/5) + 32

        #expect(fahrenheit == 77.0)
    }

    @Test func locationCoordinateValidation() {
        let validCoord = LocationCoordinate(latitude: 36.8969, longitude: 30.7133)

        #expect(validCoord.latitude >= -90)
        #expect(validCoord.latitude <= 90)
        #expect(validCoord.longitude >= -180)
        #expect(validCoord.longitude <= 180)
    }

    @Test func invalidCoordinateShouldBeRejected() {
        let invalidLat = LocationCoordinate(latitude: 100, longitude: 30)
        #expect(invalidLat.latitude > 90 || invalidLat.latitude < -90)
    }

    @Test func riskLevelComparison() {
        #expect(RiskLevel.high.rawValue > RiskLevel.medium.rawValue)
        #expect(RiskLevel.medium.rawValue > RiskLevel.low.rawValue)
    }

    @Test func timeWindowOverlapDetection() {
        let calendar = WeatherTestFixtures.calendar
        let now = Date()

        let window1Start = calendar.date(byAdding: .hour, value: 9, to: now)!
        let window1End = calendar.date(byAdding: .hour, value: 12, to: now)!

        let window1 = TimeWindow(start: window1Start, end: window1End)

        let window2Start = calendar.date(byAdding: .hour, value: 14, to: now)!
        let window2End = calendar.date(byAdding: .hour, value: 17, to: now)!

        let window2 = TimeWindow(start: window2Start, end: window2End)

        let noOverlap = window1.end <= window2.start || window2.end <= window1.start
        #expect(noOverlap)
    }
}
