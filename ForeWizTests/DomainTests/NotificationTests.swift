import Foundation
import Testing
@testable import ForeWiz

struct NotificationTests {
    @Test func notificationPlanCreation() {
        let calendar = WeatherTestFixtures.calendar
        let now = Date()
        let fireDate = calendar.date(byAdding: .hour, value: 9, to: now)!

        let plan = NotificationPlan(
            id: "test-plan",
            category: .morningBriefing,
            fireDate: fireDate,
            title: "Morning plan",
            body: "Good day for outdoor activities.",
            priority: 90,
            reason: "Test"
        )

        #expect(plan.id == "test-plan")
        #expect(plan.category == .morningBriefing)
        #expect(plan.priority == 90)
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
        #expect(NotificationAuthorizationStatus.authorized == .authorized)
        #expect(NotificationAuthorizationStatus.denied == .denied)
        #expect(NotificationAuthorizationStatus.notDetermined == .notDetermined)
    }

    @Test func notificationCategoryTitles() {
        #expect(NotificationCategory.morningBriefing.localizedTitle.isEmpty == false)
        #expect(NotificationCategory.weatherAlert.localizedTitle.isEmpty == false)
        #expect(NotificationCategory.weatherAlert.localizedTitle.isEmpty == false)
    }
}
