import Foundation

final class DefaultScheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase {
    private let notificationRepository: NotificationRepository
    private let notificationPlanningEngine: NotificationPlanningEngine
    private let dateProvider: DateProvider
    private let throttlingService: NotificationThrottlingService

    init(
        notificationRepository: NotificationRepository,
        notificationPlanningEngine: NotificationPlanningEngine,
        dateProvider: DateProvider,
        throttlingService: NotificationThrottlingService = NotificationThrottlingService()
    ) {
        self.notificationRepository = notificationRepository
        self.notificationPlanningEngine = notificationPlanningEngine
        self.dateProvider = dateProvider
        self.throttlingService = throttlingService
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
        let standardPlans = await notificationPlanningEngine.makePlans(
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

        // 3. Throttle: remove plans that violate cooldown / rate limits / dedup
        let throttledPlans = throttlingService.throttle(allPlans)

        try await notificationRepository.schedule(throttledPlans)

        // 4. Record throttling state for future cycles
        throttlingService.didSchedule(throttledPlans)

        return throttledPlans
    }
}
