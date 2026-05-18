import Testing
import Foundation
@testable import ForeWiz

struct WeatherBriefingServiceTests {
    private let service = WeatherBriefingService()
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return cal
    }()

    // MARK: - Helpers

    private func makeSnapshot(temp: Double = 22) -> WeatherSnapshot {
        let now = Date()
        let current = CurrentWeatherPoint(
            date: now,
            temperatureCelsius: temp,
            apparentTemperatureCelsius: temp,
            humidity: 0.5,
            windSpeedKph: 10,
            precipitationChance: 0.05,
            precipitationAmountMm: 0,
            uvIndex: 4,
            conditionCode: "clear",
            symbolName: "sun.max.fill",
            isDaylight: true,
            severeWeatherRisk: nil
        )
        let hourly = (0..<12).map { i in
            HourlyWeatherPoint(
                date: now.addingTimeInterval(Double(i) * 3600),
                temperatureCelsius: temp + Double(i) * 0.5,
                apparentTemperatureCelsius: temp + Double(i) * 0.5,
                humidity: 0.5,
                windSpeedKph: 10,
                precipitationChance: 0.1,
                precipitationAmountMm: 0,
                uvIndex: 4,
                conditionCode: "clear",
                symbolName: "sun.max.fill",
                isDaylight: true,
                severeWeatherRisk: nil
            )
        }
        return WeatherSnapshot(
            location: LocationCoordinate(latitude: 36.9, longitude: 30.7),
            current: current,
            hourly: hourly,
            daily: [],
            fetchedAt: now,
            attribution: nil
        )
    }

    private func makeRecommendation(
        score: Int = 80,
        decision: OutdoorDecision = .good,
        risks: [WeatherRisk] = [],
        bestWindow: TimeWindow? = nil,
        avoidWindows: [AvoidWindowRecommendation] = []
    ) -> DailyRecommendation {
        return DailyRecommendation(
            generatedAt: Date(),
            outdoorDecision: decision,
            outdoorScore: WeatherScore(rawValue: score),
            bestOutdoorWindow: bestWindow,
            bestActivityWindows: [],
            avoidWindows: avoidWindows,
            outfit: OutfitRecommendation(title: "Light t-shirt", items: ["T-shirt", "Shorts"], accessories: [], warning: nil, detailedAdvice: nil),
            risks: risks,
            summaryText: "Test",
            explanation: "\(score)/100",
            isTomorrowsRecommendation: false
        )
    }

    private func makeProfile() -> UserComfortProfile {
        UserComfortProfile(
            notificationPreferences: NotificationCategory.allCases.map {
                NotificationPreference(category: $0, isEnabled: true, preferredTime: nil)
            }
        )
    }

    // MARK: - Briefing Generation Tests

    @Test func briefingContainsAllComponents() {
        let snapshot = makeSnapshot()
        let recommendation = makeRecommendation(score: 85)
        let briefing = service.generateBriefing(snapshot: snapshot, recommendation: recommendation, profile: makeProfile(), calendar: calendar)

        #expect(briefing.narrative.headline.isEmpty == false)
        #expect(briefing.health.overallHealthScore >= 0)
        #expect(briefing.comparative.anomalyLabel.isEmpty == false)
        #expect(briefing.keyTakeaway.isEmpty == false)
        #expect(briefing.generatedAt <= Date())
    }

    @Test func briefingHasActionItems() {
        let window = TimeWindow(start: Date(), end: Date().addingTimeInterval(7200))
        let snapshot = makeSnapshot()
        let recommendation = makeRecommendation(score: 80, bestWindow: window)
        let briefing = service.generateBriefing(snapshot: snapshot, recommendation: recommendation, profile: makeProfile(), calendar: calendar)

        #expect(briefing.actionItems.isEmpty == false)
    }

    @Test func actionItemsIncludeTimingWithBestWindow() {
        let window = TimeWindow(start: Date(), end: Date().addingTimeInterval(7200))
        let snapshot = makeSnapshot()
        let recommendation = makeRecommendation(score: 80, bestWindow: window)
        let briefing = service.generateBriefing(snapshot: snapshot, recommendation: recommendation, profile: makeProfile(), calendar: calendar)

        let timingItem = briefing.actionItems.first { $0.category == .timing }
        #expect(timingItem != nil)
        #expect(timingItem?.title.isEmpty == false)
    }

    @Test func actionItemsIncludeOutfit() {
        let snapshot = makeSnapshot()
        let recommendation = makeRecommendation(score: 75)
        let briefing = service.generateBriefing(snapshot: snapshot, recommendation: recommendation, profile: makeProfile(), calendar: calendar)

        let outfitItem = briefing.actionItems.first { $0.category == .outfit }
        #expect(outfitItem != nil)
    }

    @Test func actionItemsIncludeLifestyleTip() {
        let snapshot = makeSnapshot()
        let recommendation = makeRecommendation(score: 80)
        let briefing = service.generateBriefing(snapshot: snapshot, recommendation: recommendation, profile: makeProfile(), calendar: calendar)

        let lifestyleItem = briefing.actionItems.first { $0.category == .lifestyle }
        #expect(lifestyleItem != nil)
    }

    @Test func keyTakeawayReferencesBestWindow() {
        let window = TimeWindow(start: Date(), end: Date().addingTimeInterval(7200))
        let snapshot = makeSnapshot()
        let recommendation = makeRecommendation(score: 80, bestWindow: window)
        let briefing = service.generateBriefing(snapshot: snapshot, recommendation: recommendation, profile: makeProfile(), calendar: calendar)

        #expect(briefing.keyTakeaway.isEmpty == false)
    }

    @Test func keyTakeawayForCriticalRisk() {
        let snapshot = makeSnapshot()
        let recommendation = makeRecommendation(score: 15, decision: .avoid, risks: [
            WeatherRisk(type: .storm, severity: .extreme, title: "Severe Storm", message: "Dangerous storm expected")
        ])
        let briefing = service.generateBriefing(snapshot: snapshot, recommendation: recommendation, profile: makeProfile(), calendar: calendar)

        #expect(briefing.keyTakeaway.lowercased().contains("critical") || briefing.keyTakeaway.contains("Severe Storm"))
    }

    @Test func actionItemsPrioritized() {
        let snapshot = makeSnapshot()
        let recommendation = makeRecommendation(score: 80)
        let briefing = service.generateBriefing(snapshot: snapshot, recommendation: recommendation, profile: makeProfile(), calendar: calendar)

        let priorities = briefing.actionItems.map { $0.priority }
        // Verify items are sorted by priority (ascending)
        for i in 1..<priorities.count {
            #expect(priorities[i] >= priorities[i-1], "Action items should be sorted by priority ascending")
        }
    }

    @Test func narrativeAndHealthAndComparativeAllPresent() {
        let snapshot = makeSnapshot()
        let recommendation = makeRecommendation(score: 85)
        let briefing = service.generateBriefing(snapshot: snapshot, recommendation: recommendation, profile: makeProfile(), calendar: calendar)

        #expect(briefing.narrative.moodScore >= 1)
        #expect(briefing.health.overallHealthScore >= 0)
        #expect(briefing.comparative.anomalyLabel.isEmpty == false)
    }

    @Test func healthActionItemsAddedForHighMigraineRisk() {
        // Create conditions that trigger high migraine risk
        let now = Date()
        let hourlyData: [HourlyWeatherPoint] = {
            var result = [HourlyWeatherPoint]()
            for i in 0..<12 {
                let date = now.addingTimeInterval(Double(i) * 3600)
                let temp = 22 + Double(i % 3) * 5
                let risk: RiskLevel? = (i >= 4 && i <= 6) ? .high : nil
                result.append(
                    HourlyWeatherPoint(
                        date: date,
                        temperatureCelsius: temp,
                        apparentTemperatureCelsius: temp,
                        humidity: 0.85,
                        windSpeedKph: 10,
                        precipitationChance: 0.5,
                        precipitationAmountMm: 0,
                        uvIndex: 7,
                        conditionCode: i < 6 ? "clear" : "rain",
                        symbolName: i < 6 ? "sun.max.fill" : "cloud.rain.fill",
                        isDaylight: true,
                        severeWeatherRisk: risk
                    )
                )
            }
            return result
        }()
        let current = CurrentWeatherPoint(
            date: now,
            temperatureCelsius: 22,
            apparentTemperatureCelsius: 22,
            humidity: 0.85,
            windSpeedKph: 10,
            precipitationChance: 0.5,
            precipitationAmountMm: 0,
            uvIndex: 7,
            conditionCode: "clear",
            symbolName: "sun.max.fill",
            isDaylight: true,
            severeWeatherRisk: .high
        )
        let snapshot = WeatherSnapshot(
            location: LocationCoordinate(latitude: 36.9, longitude: 30.7),
            current: current,
            hourly: hourlyData,
            daily: [],
            fetchedAt: now,
            attribution: nil
        )
        let recommendation = makeRecommendation(score: 50, decision: .moderate)
        let briefing = service.generateBriefing(snapshot: snapshot, recommendation: recommendation, profile: makeProfile(), calendar: calendar)

        let healthItems = briefing.actionItems.filter { $0.category == .health }
        #expect(healthItems.isEmpty == false)
    }
}
