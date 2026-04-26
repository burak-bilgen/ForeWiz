import Testing
@testable import WeatherAssistant

struct NotificationPlanningEngineTests {
    private let decisionEngine = DefaultWeatherDecisionEngine()
    private let notificationEngine = DefaultNotificationPlanningEngine()

    @Test func notificationPlannerCapsDeduplicatesAndRespectsQuietHours() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 7, day: 10, hour: 6)
        let quietStart = WeatherTestFixtures.date(month: 7, day: 10, hour: 11)
        let quietEnd = WeatherTestFixtures.date(month: 7, day: 10, hour: 12)
        let quietHours = TimeWindow(start: quietStart, end: quietEnd)
        let profile = WeatherTestFixtures.profile(quietHours: quietHours, maximumDailyNotifications: 2)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { (12..<16).contains($0) ? 34 : 20 },
            apparentTemperature: { (12..<16).contains($0) ? 36 : 20 },
            precipitationChance: { $0 >= 17 ? 0.80 : 0.05 },
            precipitationAmount: { $0 >= 17 ? 2.1 : 0 },
            uvIndex: { (11..<16).contains($0) ? 8 : 2 }
        )
        let recommendation = decisionEngine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: profile,
            now: now,
            calendar: calendar
        )

        let plans = notificationEngine.makePlans(
            recommendation: recommendation,
            profile: profile,
            now: now,
            calendar: calendar
        )

        #expect(plans.count == 2)
        #expect(Set(plans.map(\.category)).count == plans.count)
        #expect(plans.contains { quietHours.containsClockTime(of: $0.fireDate, calendar: calendar) } == false)
        #expect(plans.contains { $0.category == .avoidHeatWindow } == false)
    }
}
