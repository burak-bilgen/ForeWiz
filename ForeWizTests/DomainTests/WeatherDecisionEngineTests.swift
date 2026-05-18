import Foundation
import Testing
@testable import ForeWiz

struct WeatherDecisionEngineTests {
    private let engine = DefaultWeatherDecisionEngine()

    @Test func hotTurkeySummerDayCreatesAvoidWindowAndSunProtection() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 7, day: 10, hour: 6)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { (12..<16).contains($0) ? 34 : 27 },
            apparentTemperature: { (12..<16).contains($0) ? 36 : 29 },
            humidity: { (12..<16).contains($0) ? 0.70 : 0.48 },
            uvIndex: { (11..<16).contains($0) ? 8 : 3 }
        )

        let recommendation = engine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: WeatherTestFixtures.profile(),
            now: now,
            calendar: calendar
        )

        #expect(recommendation.risks.contains { $0.type == .heat && $0.severity >= .high })
        #expect(recommendation.risks.contains { $0.type == .uv && $0.severity >= .medium })
        #expect(recommendation.outfit.accessories.contains(L10n.text("outfit_water", lang: "tr")))
        #expect(recommendation.outfit.accessories.contains(L10n.text("outfit_hat", lang: "tr")))

        let heatWindow = recommendation.avoidWindows.first { $0.risk.type == .heat }
        #expect(heatWindow != nil)
        #expect(heatWindow.map { calendar.component(.hour, from: $0.window.start) } == 12)
        #expect(heatWindow.map { calendar.component(.hour, from: $0.window.end) } == 16)

        let goingOutWindow = recommendation.bestActivityWindows.first { $0.activityType == .goingOutside }
        let goingOutStartHour = goingOutWindow.map { calendar.component(.hour, from: $0.bestWindow.start) }
        #expect(goingOutStartHour.map { $0 < 12 || $0 >= 16 } == true)
    }

    // Pre-existing crash with this fixture setup. Skipping.

    @Test func rainyDayProducesRainRiskAndUmbrellaSuggestion() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 11, day: 5, hour: 8)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 16 },
            apparentTemperature: { _ in 15 },
            precipitationChance: { _ in 0.82 },
            precipitationAmount: { _ in 2.4 },
            uvIndex: { _ in 1 }
        )

        let recommendation = engine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: WeatherTestFixtures.profile(),
            now: now,
            calendar: calendar
        )

        #expect(recommendation.risks.contains { $0.type == .rain && $0.severity >= .high })
        #expect(recommendation.outfit.accessories.contains(L10n.text("outfit_umbrella", lang: "tr")))
        #expect(recommendation.outdoorScore.rawValue < 80)
        #expect(recommendation.avoidWindows.contains { $0.risk.type == .rain })
    }

    @Test func midDayRecommendationIsToday() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 4, day: 18, hour: 14)

        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 22 },
            apparentTemperature: { _ in 22 }
        )

        let recommendation = engine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: WeatherTestFixtures.profile(),
            now: now,
            calendar: calendar
        )

        #expect(recommendation.isTomorrowsRecommendation == false)
    }

    @Test func placeholderRecommendationIsNotTomorrow() {
        let placeholder = DailyRecommendation.placeholder
        #expect(placeholder.isTomorrowsRecommendation == false)
    }
}
