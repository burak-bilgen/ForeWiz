@testable import AirAssistant
import Testing

struct OutfitDecisionEngineTests {
    private let engine = DefaultWeatherDecisionEngine()

    @Test func coldSensitiveUserGetsWarmerLayerEarlier() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 5, day: 6, hour: 9)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 24 },
            apparentTemperature: { _ in 24 }
        )

        let normal = engine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: WeatherTestFixtures.profile(sensitivity: .normal),
            now: now,
            calendar: calendar
        )
        let coldSensitive = engine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: WeatherTestFixtures.profile(sensitivity: .getsColdEasily),
            now: now,
            calendar: calendar
        )

        #expect(normal.outfit.items.contains("İnce ceket") == false)
        #expect(coldSensitive.outfit.items.contains("İnce ceket"))
    }
}
