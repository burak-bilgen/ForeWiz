import Foundation

struct DefaultNotificationPlanningEngine: NotificationPlanningEngine {
    var commuteService: CommuteRouteService = DefaultCommuteRouteService()

    func makePlans(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar = .current
    ) async -> [NotificationPlan] {
        let enabledCategories = Set(
            profile.notificationPreferences
                .filter(\.isEnabled)
                .map(\.category)
        )

        var candidates: [NotificationPlan] = []

        if enabledCategories.contains(.morningBriefing),
           let morningPlan = await MorningBriefingPlanner.makePlan(
            recommendation: recommendation,
            profile: profile,
            now: now,
            calendar: calendar,
            commuteService: commuteService
           ) {
            candidates.append(morningPlan)
        }

        candidates.append(
            contentsOf: RiskPlanBuilder.makeAlertPlans(
                recommendation: recommendation,
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

        let highPriority = sorted.filter { $0.priority >= 90 }
        let regular = sorted.filter { $0.priority < 90 }

        return highPriority + Array(regular.prefix(max(0, 2 - highPriority.count)))
    }
}
