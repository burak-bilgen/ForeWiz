import Foundation
import Testing
@testable import ForeWiz

struct NotificationPlanningEngineTests {
    private let decisionEngine = DefaultWeatherDecisionEngine()
    private let notificationEngine = DefaultNotificationPlanningEngine()

    @Test func notificationPlannerCapsDeduplicatesAndRespectsQuietHours() async {
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

        let plans = await notificationEngine.makePlans(
            recommendation: recommendation,
            profile: profile,
            now: now,
            calendar: calendar
        )

        #expect(plans.isEmpty == false)
        #expect(plans.count <= 2)
        #expect(plans.contains { quietHours.containsClockTime(of: $0.fireDate, calendar: calendar) } == false)
    }

    @Test func notificationPlannerSchedulesDailyPreferencesForTomorrowAfterPreferredTime() async {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 7, day: 10, hour: 9)
        var profile = WeatherTestFixtures.profile(maximumDailyNotifications: 3)
        profile.notificationPreferences = NotificationCategory.allCases.map { category in
            let enabled = category == .morningBriefing
            let preferredTime = category == .morningBriefing
                ? DateComponents(hour: 8, minute: 0)
                : nil
            return NotificationPreference(category: category, isEnabled: enabled, preferredTime: preferredTime)
        }

        let plans = await notificationEngine.makePlans(
            recommendation: .placeholder,
            profile: profile,
            now: now,
            calendar: calendar
        )

        let categories = Set(plans.map(\.category))
        #expect(categories.isSubset(of: [.morningBriefing]))
        #expect(categories.isEmpty == false)
        #expect(plans.allSatisfy { $0.fireDate > now })
    }
}
