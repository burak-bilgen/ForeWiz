import Foundation

final class DefaultScheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase {
    private let notificationRepository: NotificationRepository
    private let notificationPlanningEngine: NotificationPlanningEngine
    private let dateProvider: DateProvider
    private let severeWeatherAlertService: SevereWeatherAlertService

    init(
        notificationRepository: NotificationRepository,
        notificationPlanningEngine: NotificationPlanningEngine,
        dateProvider: DateProvider,
        severeWeatherAlertService: SevereWeatherAlertService
    ) {
        self.notificationRepository = notificationRepository
        self.notificationPlanningEngine = notificationPlanningEngine
        self.dateProvider = dateProvider
        self.severeWeatherAlertService = severeWeatherAlertService
    }

    func execute(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile
    ) async throws -> [NotificationPlan] {
        let status = await notificationRepository.authorizationStatus()
        guard status == .authorized || status == .provisional else {
            return []
        }

        let plans = notificationPlanningEngine.makePlans(
            recommendation: recommendation,
            profile: profile,
            now: dateProvider.now,
            calendar: .current
        )

        // Integrate severe weather alerts into notification plans
        let allPlans = integrateSevereWeatherAlerts(
            plans: plans,
            recommendation: recommendation,
            profile: profile
        )

        try await notificationRepository.schedule(allPlans)
        return allPlans
    }

    // MARK: - Severe Weather Integration

    private func integrateSevereWeatherAlerts(
        plans: [NotificationPlan],
        recommendation: DailyRecommendation,
        profile: UserComfortProfile
    ) -> [NotificationPlan] {
        guard !recommendation.risks.isEmpty else { return plans }

        let isPremium = FeatureGate.isUnlocked(.severeWeatherAlerts)
        let alerts = severeWeatherAlertService.makeAlerts(from: recommendation.risks)

        guard !alerts.isEmpty else { return plans }

        var augmentedPlans = plans

        for alert in alerts {
            guard severeWeatherAlertService.shouldNotify(alert: alert, isPremium: isPremium) else {
                continue
            }

            let existingIDs = Set(plans.map(\.id))
            let alertPlan = makeSevereAlertPlan(alert: alert, existingIDs: existingIDs)

            if let plan = alertPlan {
                augmentedPlans.append(plan)
            }
        }

        return augmentedPlans
    }

    private func makeSevereAlertPlan(
        alert: SevereWeatherAlert,
        existingIDs: Set<String>
    ) -> NotificationPlan? {
        let planID = "forewiz.severe.\(alert.id).\(Int(alert.effective.timeIntervalSince1970))"

        guard !existingIDs.contains(planID) else { return nil }

        let category: NotificationCategory
        switch alert.event {
        case .tornado, .severeThunderstorm, .flashFlood:
            category = .stormWarning
        case .extremeHeat:
            category = .avoidHeatWindow
        case .extremeCold, .blizzard:
            category = .coldWarning
        case .highWind:
            category = .windWarning
        case .hail:
            category = .rainWarning
        case .denseFog:
            category = .windWarning
        }

        return NotificationPlan(
            id: planID,
            category: category,
            fireDate: alert.effective,
            title: alert.headline,
            body: "\(alert.description)\n\n\(alert.instruction)",
            priority: alert.severity == .extreme ? 100 : 90,
            reason: alert.description
        )
    }
}
