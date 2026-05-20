import Foundation

final class DefaultScheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase {
    private let notificationRepository: NotificationRepository
    private let notificationPlanningEngine: NotificationPlanningEngine
    private let dateProvider: DateProvider

    init(
        notificationRepository: NotificationRepository,
        notificationPlanningEngine: NotificationPlanningEngine,
        dateProvider: DateProvider
    ) {
        self.notificationRepository = notificationRepository
        self.notificationPlanningEngine = notificationPlanningEngine
        self.dateProvider = dateProvider
    }

    func execute(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        hourlyPoints: [HourlyWeatherPoint]
    ) async throws -> [NotificationPlan] {
        let status = await notificationRepository.authorizationStatus()
        guard status == .authorized || status == .provisional else {
            return []
        }

        let now = dateProvider.now
        let calendar = Calendar.current

        // 1. Standard plans (morning briefing + weather alerts)
        let standardPlans = notificationPlanningEngine.makePlans(
            recommendation: recommendation,
            profile: profile,
            now: now,
            calendar: calendar
        )

        // 2. Key event plans (today's important weather events as notifications)
        var allPlans = standardPlans

        let todayIsEnabled = profile.notificationPreferences
            .first { $0.category == .keyEvent }?.isEnabled ?? true

        if todayIsEnabled {
            let keyEvents = KeyEventNotificationPlanner.makeKeyEvents(
                from: hourlyPoints,
                recommendation: recommendation
            )
            let eventPlans = KeyEventNotificationPlanner.makeNotificationPlans(
                from: keyEvents,
                now: now,
                calendar: calendar
            )
            allPlans.append(contentsOf: eventPlans)
        }

        try await notificationRepository.schedule(allPlans)
        return allPlans
    }
}
