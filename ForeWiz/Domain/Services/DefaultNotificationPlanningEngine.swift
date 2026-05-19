import Foundation

struct DefaultNotificationPlanningEngine: NotificationPlanningEngine {
    func makePlans(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar = .current
    ) -> [NotificationPlan] {
        let enabledCategories = Set(
            profile.notificationPreferences
                .filter(\.isEnabled)
                .map(\.category)
        )

        var candidates: [NotificationPlan] = []

        if enabledCategories.contains(.morningBriefing),
           let morningPlan = MorningBriefingPlanner.makePlan(
            recommendation: recommendation,
            profile: profile,
            now: now,
            calendar: calendar
           ) {
            candidates.append(morningPlan)
        }

        if enabledCategories.contains(.outfitSuggestion),
           let outfitPlan = OutfitPlanBuilder.makePlan(
             recommendation: recommendation,
             profile: profile,
             now: now,
             calendar: calendar
            ) {
            candidates.append(outfitPlan)
        }

        if enabledCategories.contains(.bestRunWindow),
           let runningWindow = recommendation.bestActivityWindows.first(where: { $0.activityType == .goingOutside }),
           let plan = ActivityPlanBuilder.makePlan(activityRecommendation: runningWindow, now: now, calendar: calendar),
           NotificationPlanHelpers.isWorthNotifying(plan: plan, calendar: calendar) {
            candidates.append(plan)
        }

        candidates.append(
            contentsOf: RiskPlanBuilder.makeSmartPlans(
                recommendation: recommendation,
                enabledCategories: enabledCategories,
                now: now,
                calendar: calendar
            )
        )
        candidates.append(
            contentsOf: RiskPlanBuilder.makeImmediatePlans(
                recommendation: recommendation,
                enabledCategories: enabledCategories,
                now: now,
                calendar: calendar
            )
        )

        let deduplicated = NotificationPlanHelpers.deduplicateSmart(candidates)

        let filtered = deduplicated
            .filter { $0.fireDate >= now }
            .filter { NotificationPlanHelpers.isQuiet($0.fireDate, quietHours: profile.quietHours, calendar: calendar) == false }
            .filter { NotificationPlanHelpers.isWorthNotifying(plan: $0, calendar: calendar) }

        let sorted = filtered.sorted { p0, p1 in
            if p0.priority == p1.priority {
                if p0.fireDate == p1.fireDate {
                    return p0.category.rawValue < p1.category.rawValue
                }
                return p0.fireDate < p1.fireDate
            }
            return p0.priority > p1.priority
        }

        return Array(sorted.prefix(profile.maximumDailyNotifications.clamped(to: 1...3)))
    }
}
