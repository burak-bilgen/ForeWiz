import Testing
import Foundation
@testable import ForeWiz

struct WeatherNarrativeServiceTests {
    private let service = WeatherNarrativeService()
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return cal
    }()

    private func makeSnapshot(
        temp: Double = 22,
        humidity: Double? = 0.5,
        wind: Double? = 10,
        uv: Int? = 4,
        isDaylight: Bool = true,
        condition: String? = "clear"
    ) -> WeatherSnapshot {
        let now = Date()
        let current = CurrentWeatherPoint(
            date: now,
            temperatureCelsius: temp,
            apparentTemperatureCelsius: temp,
            humidity: humidity,
            windSpeedKph: wind,
            precipitationChance: 0.05,
            precipitationAmountMm: 0,
            uvIndex: uv,
            conditionCode: condition,
            symbolName: isDaylight ? "sun.max.fill" : "moon.stars.fill",
            isDaylight: isDaylight,
            severeWeatherRisk: nil
        )
        return WeatherSnapshot(
            location: LocationCoordinate(latitude: 36.9, longitude: 30.7),
            current: current,
            hourly: [],
            daily: [],
            fetchedAt: now,
            attribution: nil
        )
    }

    private func makeRecommendation(
        score: Int = 80,
        decision: OutdoorDecision = .good,
        risks: [WeatherRisk] = [],
        bestWindow: TimeWindow? = nil
    ) -> DailyRecommendation {
        return DailyRecommendation(
            generatedAt: Date(),
            outdoorDecision: decision,
            outdoorScore: WeatherScore(rawValue: score),
            bestOutdoorWindow: bestWindow,
            bestActivityWindows: [],
            avoidWindows: [],
            outfit: OutfitRecommendation(title: "title", items: [], accessories: [], warning: nil, detailedAdvice: nil),
            risks: risks,
            summaryText: "Test",
            explanation: "\(score)/100",
            isTomorrowsRecommendation: false
        )
    }

    private func makeRisk(type: WeatherRiskType, severity: RiskLevel, title: String = "Test", message: String = "Test message") -> WeatherRisk {
        WeatherRisk(type: type, severity: severity, title: title, message: message)
    }

    @Test func energeticPersonalityInIdealConditions() {
        let snapshot = makeSnapshot(temp: 25, isDaylight: true)
        let recommendation = makeRecommendation(score: 90)
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.personality == .energetic)
        #expect(narrative.moodScore >= 7)
    }

    @Test func dramaticPersonalityInStorm() {
        let snapshot = makeSnapshot(temp: 28, condition: "thunderstorm")
        let recommendation = makeRecommendation(score: 30, decision: .avoid, risks: [
            makeRisk(type: .storm, severity: .high, title: "Storm", message: "Severe thunderstorm")
        ])
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.personality == .dramatic)
        #expect(narrative.moodScore <= 5)
    }

    @Test func cozyPersonalityInCold() {
        let snapshot = makeSnapshot(temp: 3)
        let recommendation = makeRecommendation(score: 40, decision: .risky, risks: [
            makeRisk(type: .cold, severity: .high, title: "Cold", message: "Freezing")
        ])
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.personality == .cozy)
    }

    @Test func lazyPersonalityInHotHumid() {
        let snapshot = makeSnapshot(temp: 33, humidity: 0.7)
        let recommendation = makeRecommendation(score: 20, decision: .risky, risks: [
            makeRisk(type: .heat, severity: .high, title: "Heat", message: "Extreme heat")
        ])
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.personality == .lazy)
    }

    @Test func mysteriousPersonalityInFog() {
        let snapshot = makeSnapshot(temp: 15, condition: "fog")
        let recommendation = makeRecommendation(score: 60)
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.personality == .mysterious)
    }

    @Test func headlineIsNotEmpty() {
        let snapshot = makeSnapshot(temp: 22)
        let recommendation = makeRecommendation(score: 85)
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.headline.isEmpty == false)
    }

    @Test func headlineChangesWithPersonality() {
        let sunny = service.generateNarrative(
            snapshot: makeSnapshot(temp: 25, isDaylight: true),
            recommendation: makeRecommendation(score: 90),
            calendar: calendar
        )
        let stormy = service.generateNarrative(
            snapshot: makeSnapshot(temp: 28, condition: "thunderstorm"),
            recommendation: makeRecommendation(score: 30, decision: .avoid, risks: [
                makeRisk(type: .storm, severity: .high, title: "Storm", message: "Storm")
            ]),
            calendar: calendar
        )
        #expect(sunny.headline != stormy.headline)
    }

    @Test func storyIsNotEmpty() {
        let snapshot = makeSnapshot(temp: 20)
        let recommendation = makeRecommendation(score: 75)
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.story.isEmpty == false)
    }

    @Test func proTipGeneratedForBestWindow() {
        let window = TimeWindow(start: Date(), end: Date().addingTimeInterval(7200))
        let snapshot = makeSnapshot(temp: 22)
        let recommendation = makeRecommendation(score: 80, bestWindow: window)
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.proTip.isEmpty == false)
    }

    @Test func proTipForStorm() {
        let snapshot = makeSnapshot(temp: 28, condition: "thunderstorm")
        let recommendation = makeRecommendation(score: 25, decision: .avoid, risks: [
            makeRisk(type: .storm, severity: .extreme, title: "Storm", message: "Dangerous storm")
        ])
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.proTip.isEmpty == false)
    }

    @Test func proTipForHighUV() {
        let snapshot = makeSnapshot(temp: 30, uv: 8)

        let recommendation = makeRecommendation(score: 40, decision: .moderate, risks: [
            makeRisk(type: .uv, severity: .high, title: "UV", message: "High UV")
        ])
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.proTip.isEmpty == false)
    }

    @Test func perfectConditionsGiveHighMood() {
        let snapshot = makeSnapshot(temp: 22)
        let recommendation = makeRecommendation(score: 95)
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.moodScore >= 8)
        #expect(narrative.moodLabel.isEmpty == false)
        #expect(narrative.moodSymbol.isEmpty == false)
    }

    @Test func stormyConditionsGiveLowMood() {
        let snapshot = makeSnapshot(temp: 35, condition: "thunderstorm")
        let recommendation = makeRecommendation(score: 15, decision: .avoid, risks: [
            makeRisk(type: .storm, severity: .extreme, title: "Storm", message: "Extreme storm"),
            makeRisk(type: .heat, severity: .high, title: "Heat", message: "Extreme heat")
        ])
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.moodScore <= 5)
    }

    @Test func moodScoreBoundaries() {
        let snapshot = makeSnapshot(temp: 40, condition: "thunderstorm")
        let recommendation = makeRecommendation(score: 5, decision: .avoid, risks: [
            makeRisk(type: .storm, severity: .extreme, title: "Storm", message: ""),
            makeRisk(type: .heat, severity: .extreme, title: "Heat", message: "")
        ])
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.moodScore >= 1, "Mood score should never drop below 1")
        #expect(narrative.moodScore <= 10, "Mood score should never exceed 10")
    }

    @Test func narrativeHasAllRequiredFields() {
        let snapshot = makeSnapshot(temp: 18)
        let recommendation = makeRecommendation(score: 70)
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.headline.isEmpty == false)
        #expect(narrative.story.isEmpty == false)
        #expect(narrative.proTip.isEmpty == false)
        #expect(narrative.moodLabel.isEmpty == false)
        #expect(narrative.moodSymbol.isEmpty == false)
    }

    @Test func refreshingRainWithoutStorm() {
        let snapshot = makeSnapshot(temp: 18, condition: "rain")
        let recommendation = makeRecommendation(score: 50, risks: [
            makeRisk(type: .rain, severity: .low, title: "Rain", message: "Light rain")
        ])
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.personality == .refreshing)
    }

    @Test func stubbornPersonalityInMixedConditions() {

        let snapshot = makeSnapshot(temp: 18, isDaylight: false, condition: "cloudy")
        let recommendation = makeRecommendation(score: 60)
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)

        #expect(narrative.personality == .serene)
    }

    @Test func adventurousInHighWind() {
        let snapshot = makeSnapshot(temp: 26, wind: 35)
        let recommendation = makeRecommendation(score: 60, risks: [
            makeRisk(type: .wind, severity: .high, title: "Wind", message: "Strong winds")
        ])
        let narrative = service.generateNarrative(snapshot: snapshot, recommendation: recommendation, calendar: calendar)
        #expect(narrative.personality == .adventurous)
    }
}
