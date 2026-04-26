import Foundation

protocol NotificationPlanningEngine {
    func makePlans(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> [NotificationPlan]
}
