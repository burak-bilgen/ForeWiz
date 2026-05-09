import Testing
@testable import Weathra

struct DateTimeHelpersTests {
    @Test func timeWindowShortDisplayTextFormatsCorrectly() {
        let calendar = WeatherTestFixtures.calendar
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        let end = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()

        let window = TimeWindow(start: start, end: end)
        let displayText = window.shortDisplayText

        #expect(displayText.contains("09:00"))
        #expect(displayText.contains("12:00"))
    }

    @Test func dailyForecastItemDayNameForToday() {
        let calendar = WeatherTestFixtures.calendar
        let today = Date()

        let item = DailyForecastItem(
            id: "1",
            date: today,
            highTemp: 28,
            lowTemp: 18,
            conditionCode: "clear",
            precipitationChance: 0.1
        )

        #expect(item.isToday == true)
        #expect(item.dayName == "Bugün")
    }

    @Test func dailyForecastItemDayNameForTomorrow() {
        let calendar = WeatherTestFixtures.calendar
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        let item = DailyForecastItem(
            id: "1",
            date: tomorrow,
            highTemp: 28,
            lowTemp: 18,
            conditionCode: "clear",
            precipitationChance: 0.1
        )

        #expect(item.dayName == "Yarın")
    }

    @Test func hourlyScoreItemCalculation() {
        let hour = 14
        let score = 85

        let item = HourlyScoreItem(hour: hour, score: score)

        #expect(item.hour == 14)
        #expect(item.score == 85)
    }

    @Test func weatherRiskSeverityComparison() {
        let lowRisk = WeatherRisk(
            id: UUID(),
            type: .uv,
            severity: .low,
            title: "UV",
            message: "Low UV"
        )

        let highRisk = WeatherRisk(
            id: UUID(),
            type: .uv,
            severity: .high,
            title: "UV",
            message: "High UV"
        )

        #expect(highRisk.severity > lowRisk.severity)
    }

    @Test func outdoorDecisionLocalizedTitle() {
        #expect(OutdoorDecision.goOut.localizedTitle == "Dışarı Çık")
        #expect(OutdoorDecision.stayIn.localizedTitle == "İçeride Kal")
        #expect(OutdoorDecision.cautious.localizedTitle == "Dikkatli Ol")
    }

    @Test func activityTypeLocalizedTitle() {
        #expect(ActivityType.running.localizedTitle == "Koşu")
        #expect(ActivityType.walking.localizedTitle == "Yürüyüş")
        #expect(ActivityType.cycling.localizedTitle == "Bisiklet")
        #expect(ActivityType.goingOutside.localizedTitle == "Dışarı Çıkış")
    }

    @Test func allergyTypeLocalizedTitle() {
        #expect(AllergyType.grass.localizedTitle == "Çim Poleni")
        #expect(AllergyType.tree.localizedTitle == "Ağaç Poleni")
        #expect(AllergyType.weed.localizedTitle == "Ot Poleni")
    }
}