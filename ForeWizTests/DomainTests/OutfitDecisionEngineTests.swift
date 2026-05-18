import Testing
@testable import ForeWiz

struct OutfitDecisionEngineTests {
    private let engine = DefaultWeatherDecisionEngine()

    @Test func warmWeatherOutfitIsLight() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 7, day: 10, hour: 14)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 30 },
            apparentTemperature: { _ in 32 }
        )

        let recommendation = engine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: WeatherTestFixtures.profile(),
            now: now,
            calendar: calendar
        )

        let tshirtKey = L10n.text("outfit_light_tshirt")
        #expect(recommendation.outfit.items.contains(tshirtKey))
    }

    @Test func coldWeatherOutfitIncludesWarmLayers() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 1, day: 15, hour: 10)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 5 },
            apparentTemperature: { _ in 3 }
        )

        let recommendation = engine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: WeatherTestFixtures.profile(),
            now: now,
            calendar: calendar
        )

        let coatKey = L10n.text("outfit_winter_coat")
        #expect(recommendation.outfit.items.contains(coatKey))
    }

    @Test func moderateTemperatureIncludesLightJacket() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 5, day: 6, hour: 9)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 20 },
            apparentTemperature: { _ in 20 }
        )

        let recommendation = engine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: WeatherTestFixtures.profile(),
            now: now,
            calendar: calendar
        )

        let lightJacketKey = L10n.text("outfit_light_jacket")
        #expect(recommendation.outfit.items.contains(lightJacketKey))
    }
}
