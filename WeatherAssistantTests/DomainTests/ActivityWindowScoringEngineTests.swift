import Testing
@testable import WeatherAssistant

struct ActivityWindowScoringEngineTests {
    private let engine = DefaultActivityWindowScoringEngine()

    @Test func windyDayPenalizesCyclingMoreThanWalking() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 3, day: 12, hour: 10)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 18 },
            apparentTemperature: { _ in 18 },
            windSpeed: { _ in 38 }
        )
        let hour = snapshot.hourly[4]
        let profile = WeatherTestFixtures.profile()

        let walkingScore = engine.score(hour: hour, activity: .walking, profile: profile, calendar: calendar)
        let cyclingScore = engine.score(hour: hour, activity: .cycling, profile: profile, calendar: calendar)

        #expect(cyclingScore.rawValue < walkingScore.rawValue)
    }
}
