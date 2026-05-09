import Testing
@testable import Weathra

struct DecisionEngineIntegrationTests {
    private let decisionEngine = DefaultWeatherDecisionEngine()
    private let outfitEngine = DefaultOutfitDecisionEngine()
    private let activityEngine = DefaultActivityWindowScoringEngine()

    @Test func fullRecommendationForGoodWeather() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 5, day: 15, hour: 10)

        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 24 },
            apparentTemperature: { _ in 24 },
            humidity: { _ in 0.5 },
            windSpeed: { _ in 8 },
            precipitationChance: { _ in 0.0 },
            uvIndex: { _ in 4 }
        )

        let profile = WeatherTestFixtures.profile(sensitivity: .normal)
        let recommendation = decisionEngine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: profile,
            now: now,
            calendar: calendar
        )

        #expect(recommendation.outdoorScore >= 80)
        #expect(recommendation.outdoorDecision == .goOut)
    }

    @Test func fullRecommendationForBadWeather() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 1, day: 15, hour: 14)

        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 2 },
            apparentTemperature: { _ in -2 },
            humidity: { _ in 0.85 },
            windSpeed: { _ in 35 },
            precipitationChance: { _ in 0.7 },
            uvIndex: { _ in 1 }
        )

        let profile = WeatherTestFixtures.profile(sensitivity: .normal)
        let recommendation = decisionEngine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: profile,
            now: now,
            calendar: calendar
        )

        #expect(recommendation.outdoorScore < 50)
        #expect(recommendation.outdoorDecision == .stayIn)
    }

    @Test func outdoorDecisionForTemperatureThreshold() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 7, day: 15, hour: 14)

        let hotSnapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 38 },
            apparentTemperature: { _ in 42 },
            humidity: { _ in 0.3 },
            windSpeed: { _ in 5 },
            precipitationChance: { _ in 0.0 },
            uvIndex: { _ in 10 }
        )

        let profile = WeatherTestFixtures.profile(sensitivity: .normal)
        let recommendation = decisionEngine.makeDailyRecommendation(
            snapshot: hotSnapshot,
            profile: profile,
            now: now,
            calendar: calendar
        )

        #expect(recommendation.outdoorDecision == .stayIn)
    }

    @Test func riskClassificationForHighUV() {
        let classifier = DefaultWeatherRiskClassifier()

        let highUVPoint = HourlyWeatherPoint(
            date: Date(),
            temperatureCelsius: 28,
            apparentTemperatureCelsius: 30,
            humidity: 0.4,
            windSpeedKph: 10,
            precipitationChance: 0.0,
            precipitationAmountMm: 0,
            uvIndex: 11,
            conditionCode: "clear",
            isDaylight: true,
            severeWeatherRisk: nil,
            pollenLevel: nil,
            airQualityIndex: nil,
            pm25Level: nil
        )

        let risks = classifier.classifyRisks(for: highUVPoint)
        #expect(risks.contains { $0.type == .uv && $0.severity == .high })
    }

    @Test func riskClassificationForStorm() {
        let classifier = DefaultWeatherRiskClassifier()

        let stormPoint = HourlyWeatherPoint(
            date: Date(),
            temperatureCelsius: 22,
            apparentTemperatureCelsius: 20,
            humidity: 0.9,
            windSpeedKph: 55,
            precipitationChance: 0.9,
            precipitationAmountMm: 25,
            uvIndex: 1,
            conditionCode: "thunderstorm",
            isDaylight: true,
            severeWeatherRisk: .high,
            pollenLevel: nil,
            airQualityIndex: nil,
            pm25Level: nil
        )

        let risks = classifier.classifyRisks(for: stormPoint)
        #expect(risks.contains { $0.type == .storm && $0.severity == .high })
        #expect(risks.contains { $0.type == .rain && $0.severity >= .medium })
    }

    @Test func outfitRecommendationForRain() {
        let rainRisk = WeatherRisk(
            id: UUID(),
            type: .rain,
            severity: .high,
            title: "Rain",
            message: "Heavy rain expected"
        )

        let input = OutfitRecommendationInput(
            current: HourlyWeatherPoint(
                date: Date(),
                temperatureCelsius: 18,
                apparentTemperatureCelsius: 16,
                humidity: 0.8,
                windSpeedKph: 15,
                precipitationChance: 0.8,
                precipitationAmountMm: 10,
                uvIndex: 1,
                conditionCode: "rain",
                isDaylight: true,
                severeWeatherRisk: nil,
                pollenLevel: nil,
                airQualityIndex: nil,
                pm25Level: nil
            ),
            profile: UserComfortProfile(
                temperatureSensitivity: .normal,
                preferredActivities: Set(ActivityType.allCases),
                quietHours: nil,
                notificationPreferences: [],
                maximumDailyNotifications: 2
            ),
            hourly: [],
            risks: [rainRisk],
            avoidWindows: []
        )

        let outfit = outfitEngine.recommendOutfit(input: input)

        #expect(outfit.items.contains { $0.contains("rain") || $0.contains("yağmurluk") })
        #expect(outfit.warning != nil)
    }

    @Test func activityScoringForOptimalConditions() {
        let now = Date()
        let calendar = WeatherTestFixtures.calendar

        let goodConditions: [HourlyWeatherPoint] = (8...18).map { hour in
            HourlyWeatherPoint(
                date: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now,
                temperatureCelsius: 22,
                apparentTemperatureCelsius: 22,
                humidity: 0.5,
                windSpeedKph: 10,
                precipitationChance: 0.0,
                precipitationAmountMm: 0,
                uvIndex: 5,
                conditionCode: "clear",
                isDaylight: true,
                severeWeatherRisk: nil,
                pollenLevel: nil,
                airQualityIndex: nil,
                pm25Level: nil
            )
        }

        let score = activityEngine.scoreWindow(
            points: goodConditions,
            activity: .running,
            calendar: calendar
        )

        #expect(score >= 85)
    }

    @Test func activityScoringPenalizesBadConditions() {
        let now = Date()
        let calendar = WeatherTestFixtures.calendar

        let badConditions: [HourlyWeatherPoint] = (8...18).map { hour in
            HourlyWeatherPoint(
                date: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now,
                temperatureCelsius: 38,
                apparentTemperatureCelsius: 42,
                humidity: 0.9,
                windSpeedKph: 40,
                precipitationChance: 0.7,
                precipitationAmountMm: 15,
                uvIndex: 11,
                conditionCode: "thunderstorm",
                isDaylight: true,
                severeWeatherRisk: .medium,
                pollenLevel: nil,
                airQualityIndex: nil,
                pm25Level: nil
            )
        }

        let score = activityEngine.scoreWindow(
            points: badConditions,
            activity: .cycling,
            calendar: calendar
        )

        #expect(score < 40)
    }
}