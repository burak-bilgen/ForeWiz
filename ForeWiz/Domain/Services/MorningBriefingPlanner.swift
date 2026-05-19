import Foundation

// MARK: - Morning Briefing Planner

/// Builds the morning briefing notification plan from weather recommendation data.
enum MorningBriefingPlanner {

    static func makePlan(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let preference = profile.notificationPreferences.first { $0.category == .morningBriefing }
        let preferredTime = preference?.preferredTime ?? DateComponents(hour: 7, minute: 30)

        guard let fireDate = calendar.nextDate(
            after: now,
            matching: preferredTime,
            matchingPolicy: .nextTime
        ) else { return nil }

        let body = buildBody(recommendation: recommendation)

        return NotificationPlan(
            id: NotificationPlanHelpers.stableID(category: .morningBriefing, fireDate: fireDate, calendar: calendar),
            category: .morningBriefing,
            fireDate: fireDate,
            title: L10n.text("todays_weather_plan_is_ready"),
            body: body,
            priority: 70,
            reason: L10n.text("notification_morning_reason")
        )
    }

    // MARK: - Body Builder

    private static func buildBody(recommendation: DailyRecommendation) -> String {
        let opening: String
        switch recommendation.outdoorDecision {
        case .good:
            opening = L10n.text("today_looks_comfortable_for_outdoor")
        case .moderate:
            opening = L10n.text("outdoor_plans_are_fine_today")
        case .risky:
            opening = L10n.text("build_todays_outdoor_plan_carefully")
        case .avoid:
            opening = L10n.text("it_is_safer_to_keep")
        }

        var sentences = [opening]
        if let bestWindow = recommendation.bestOutdoorWindow {
            sentences.append(String(format: L10n.text("morning_best_time_format"), bestWindow.shortDisplayText))
        }

        if let risk = NotificationPlanHelpers.dominantRisk(in: recommendation), risk.severity >= .high {
            sentences.append(String(format: L10n.text("morning_risk_format"), risk.title, NotificationPlanHelpers.actionText(for: risk)))
        }

        return sentences.joined(separator: " ")
    }
}
