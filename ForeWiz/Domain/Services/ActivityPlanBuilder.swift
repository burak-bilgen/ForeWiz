import Foundation

// MARK: - Activity Plan Builder

/// Builds the best-activity-window notification plan from weather recommendation data.
enum ActivityPlanBuilder {

    static func makePlan(
        activityRecommendation: ActivityRecommendation,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let fireDate = activityRecommendation.bestWindow.start
        guard fireDate >= now.addingTimeInterval(30 * 60) else { return nil }

        let time = activityRecommendation.bestWindow.shortDisplayText
        let activityTitle = activityRecommendation.activityType.localizedTitle
        let body = buildBody(
            activityTitle: activityTitle,
            time: time,
            score: activityRecommendation.score.rawValue
        )

        return NotificationPlan(
            id: NotificationPlanHelpers.stableID(category: .bestRunWindow, fireDate: fireDate, calendar: calendar),
            category: .bestRunWindow,
            fireDate: fireDate,
            title: String(format: L10n.text("activity_best_title_format"), activityTitle),
            body: body,
            priority: 80,
            reason: activityRecommendation.reason
        )
    }

    // MARK: - Body Builder

    private static func buildBody(activityTitle: String, time: String, score: Int) -> String {
        if score >= 80 {
            return String(format: L10n.text("activity_best_body_format"), time, score)
        }
        if score >= 60 {
            return String(format: L10n.text("activity_good_body_format"), time, score, activityTitle)
        }
        return String(format: L10n.text("activity_moderate_body_format"), time, score)
    }
}
