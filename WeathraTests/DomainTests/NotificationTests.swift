import Testing
@testable import Weathra

struct NotificationTests {
    @Test func notificationPlanCreation() {
        let calendar = WeatherTestFixtures.calendar
        let now = Date()
        let start = calendar.date(byAdding: .hour, value: 9, to: now)!
        let end = calendar.date(byAdding: .hour, value: 12, to: now)!

        let window = TimeWindow(start: start, end: end)

        let plan = NotificationPlan(
            id: "test-plan",
            category: .morningBriefing,
            timeWindow: window,
            recommendation: "Good day for outdoor activities",
            priority: .high
        )

        #expect(plan.id == "test-plan")
        #expect(plan.category == .morningBriefing)
        #expect(plan.priority == .high)
    }

    @Test func notificationPreferenceMapping() {
        let pref = NotificationPreference(
            category: .morningBriefing,
            isEnabled: true,
            preferredTime: DateComponents(hour: 8, minute: 0)
        )

        #expect(pref.isEnabled == true)
        #expect(pref.preferredTime?.hour == 8)
    }

    @Test func notificationAuthorizationStatusMapping() {
        #expect(NotificationAuthorizationStatus.authorized.rawValue == "authorized")
        #expect(NotificationAuthorizationStatus.denied.rawValue == "denied")
        #expect(NotificationAuthorizationStatus.notDetermined.rawValue == "notDetermined")
    }

    @Test func notificationCategoryTitles() {
        #expect(NotificationCategory.morningBriefing.localizedTitle.isEmpty == false)
        #expect(NotificationCategory.severeWeather.localizedTitle.isEmpty == false)
    }
}