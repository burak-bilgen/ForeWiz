import Foundation
import Testing
@testable import ForeWiz

struct DateTimeHelpersTests {
    @Test func timeWindowShortDisplayTextFormatsCorrectly() {
        let calendar = WeatherTestFixtures.calendar
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        let end = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()

        let window = TimeWindow(start: start, end: end)
        let displayText = window.shortDisplayText

        #expect(displayText.contains(":"))
        #expect(displayText.contains("–"))
    }

    @Test func dailyForecastItemDayNameForToday() {
        let calendar = WeatherTestFixtures.calendar
        let today = Date()

        let item = DailyForecastItem(
            dayName: "Bugün",
            date: today,
            highTemp: 28,
            lowTemp: 18,
            conditionSymbol: "sun.max.fill",
            outdoorScore: 82,
            outdoorDecision: .good,
            isToday: true,
            precipitationChance: 0.1
        )

        #expect(item.isToday == true)
        #expect(item.dayName == "Bugün")
    }

    @Test func dailyForecastItemDayNameForTomorrow() {
        let calendar = WeatherTestFixtures.calendar
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        let item = DailyForecastItem(
            dayName: "Yarın",
            date: tomorrow,
            highTemp: 28,
            lowTemp: 18,
            conditionSymbol: "sun.max.fill",
            outdoorScore: 74,
            outdoorDecision: .moderate,
            isToday: false,
            precipitationChance: 0.1
        )

        #expect(item.dayName == "Yarın")
    }

    @Test func hourlyScoreItemCalculation() {
        let hour = 14
        let score = 85

        let item = HourlyScoreItem(
            date: Date(),
            hour: hour,
            score: score,
            symbolName: "sun.max.fill",
            temperatureText: "24°",
            precipitationChance: 0.1
        )

        #expect(item.hour == 14)
        #expect(item.score == 85)
    }

    @Test func weatherRiskSeverityComparison() {
        let lowRisk = WeatherRisk(
            type: .uv,
            severity: .low,
            title: "UV",
            message: "Low UV"
        )

        let highRisk = WeatherRisk(
            type: .uv,
            severity: .high,
            title: "UV",
            message: "High UV"
        )

        #expect(highRisk.severity > lowRisk.severity)
    }

    @Test func outdoorDecisionLocalizedTitle() {
        L10n.configure(language: .turkish)

        #expect(OutdoorDecision.good.localizedTitle.isEmpty == false)
        #expect(OutdoorDecision.moderate.localizedTitle.isEmpty == false)
        #expect(OutdoorDecision.risky.localizedTitle.isEmpty == false)
        #expect(OutdoorDecision.avoid.localizedTitle.isEmpty == false)
    }

    @Test func activityTypeLocalizedTitle() {
        L10n.configure(language: .turkish)

        #expect(ActivityType.running.localizedTitle == "Koşu")
        #expect(ActivityType.walking.localizedTitle == "Yürüyüş")
        #expect(ActivityType.cycling.localizedTitle == "Bisiklet")
        #expect(ActivityType.goingOutside.localizedTitle.isEmpty == false)
    }

