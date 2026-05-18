import Testing
import Foundation
@testable import ForeWiz

@Suite("Activity Window Scoring Tests")
struct ActivityWindowScoringEngineTests {

    @Test("Wind reduces going-out score")
    func testWindPenalty() {
        let calendar = WeatherTestFixtures.calendar
        let engine = DefaultActivityWindowScoringEngine()
        let now = WeatherTestFixtures.date(month: 6, day: 15, hour: 14)

        let calmHour = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 22 },
            apparentTemperature: { _ in 22 },
            windSpeed: { _ in 5 }
        ).hourly[4]

        let windyHour = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 22 },
            apparentTemperature: { _ in 22 },
            windSpeed: { _ in 38 }
        ).hourly[4]

        let profile = WeatherTestFixtures.profile()

        let calmScore = engine.score(hour: calmHour, activity: .goingOutside, profile: profile, calendar: calendar)
        let windyScore = engine.score(hour: windyHour, activity: .goingOutside, profile: profile, calendar: calendar)

        #expect(windyScore.rawValue < calmScore.rawValue)
    }
}
