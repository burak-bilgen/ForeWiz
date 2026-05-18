import Foundation
import Testing
@testable import ForeWiz

struct DecisionEngineIntegrationTests {
    private let activityEngine = DefaultActivityWindowScoringEngine()
    private let outfitEngine = DefaultOutfitDecisionEngine()

    @Test func fullRecommendationForComfortableWeatherIsActionable() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 5, day: 15, hour: 10)
        let decisionEngine = DefaultWeatherDecisionEngine(
            activityWindowScoringEngine: activityEngine,
            outfitDecisionEngine: outfitEngine
        )
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 24 },
            apparentTemperature: { _ in 24 },
            humidity: { _ in 0.5 },
            windSpeed: { _ in 8 },
            precipitationChance: { _ in 0.0 },
            uvIndex: { _ in 4 }
        )

        let recommendation = decisionEngine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: WeatherTestFixtures.profile(),
            now: now,
            calendar: calendar
        )

        #expect(recommendation.outdoorScore.rawValue >= 70)
        #expect(recommendation.bestOutdoorWindow != nil)
        #expect(recommendation.outfit.items.isEmpty == false)
    }

    @Test func riskClassifierSurfacesStormAndRainRisk() {
        let classifier = DefaultWeatherRiskClassifier(activityWindowScoringEngine: activityEngine)
        let stormPoint = makeHour(
            windSpeedKph: 55,
            precipitationChance: 0.9,
            precipitationAmountMm: 25,
            conditionCode: "thunderstorm",
            severeWeatherRisk: .high
        )

        let risks = classifier.risks(for: stormPoint, calendar: WeatherTestFixtures.calendar)

        #expect(risks.contains { $0.type == WeatherRiskType.storm && $0.severity >= .high })
        #expect(risks.contains { $0.type == WeatherRiskType.rain && $0.severity >= .medium })
    }

    @Test func outfitRecommendationRespondsToRainRisk() {
        L10n.configure(language: .turkish)
        let rainRisk = WeatherRisk(
            type: .rain,
            severity: .high,
            title: "Yağmur",
            message: "Kuvvetli yağmur bekleniyor"
        )
        let current = CurrentWeatherPoint(
            date: Date(),
            temperatureCelsius: 18,
            apparentTemperatureCelsius: 16,
            humidity: 0.8,
            windSpeedKph: 15,
            precipitationChance: 0.8,
            precipitationAmountMm: 10,
            uvIndex: 1,
            conditionCode: "rain",
            symbolName: "cloud.rain.fill",
            isDaylight: true,
            severeWeatherRisk: nil
        )
        let input = OutfitRecommendationInput(
            current: current,
            hourly: [],
            profile: WeatherTestFixtures.profile(),
            risks: [rainRisk],
            avoidWindows: [],
            calendar: WeatherTestFixtures.calendar
        )

        let outfit = outfitEngine.recommendOutfit(input: input)

        #expect(outfit.items.isEmpty == false)
        #expect(outfit.warning != nil || outfit.accessories.isEmpty == false)
    }

    @Test func activityScoringPenalizesBadConditions() {
        let profile = WeatherTestFixtures.profile()
        let calendar = WeatherTestFixtures.calendar
        let goodHour = makeHour(
            temperatureCelsius: 22,
            apparentTemperatureCelsius: 22,
            windSpeedKph: 8,
            precipitationChance: 0.0,
            precipitationAmountMm: 0,
            uvIndex: 4
        )
        let badHour = makeHour(
            temperatureCelsius: 38,
            apparentTemperatureCelsius: 42,
            humidity: 0.9,
            windSpeedKph: 40,
            precipitationChance: 0.7,
            precipitationAmountMm: 15,
            uvIndex: 11,
            conditionCode: "thunderstorm",
            severeWeatherRisk: .medium
        )

        let goodScore = activityEngine.score(hour: goodHour, activity: .goingOutside, profile: profile, calendar: calendar)
        let badScore = activityEngine.score(hour: badHour, activity: .goingOutside, profile: profile, calendar: calendar)

        #expect(goodScore.rawValue > badScore.rawValue)
    }

    private func makeHour(
        date: Date = WeatherTestFixtures.date(month: 5, day: 15, hour: 14),
        temperatureCelsius: Double = 22,
        apparentTemperatureCelsius: Double = 22,
        humidity: Double? = 0.5,
        windSpeedKph: Double? = 10,
        precipitationChance: Double? = 0,
        precipitationAmountMm: Double? = 0,
        uvIndex: Int? = 3,
        conditionCode: String? = "clear",
        severeWeatherRisk: RiskLevel? = nil
    ) -> HourlyWeatherPoint {
        HourlyWeatherPoint(
            date: date,
            temperatureCelsius: temperatureCelsius,
            apparentTemperatureCelsius: apparentTemperatureCelsius,
            humidity: humidity,
            windSpeedKph: windSpeedKph,
            precipitationChance: precipitationChance,
            precipitationAmountMm: precipitationAmountMm,
            uvIndex: uvIndex,
            conditionCode: conditionCode,
            symbolName: nil,
            isDaylight: true,
            severeWeatherRisk: severeWeatherRisk
        )
    }
}
