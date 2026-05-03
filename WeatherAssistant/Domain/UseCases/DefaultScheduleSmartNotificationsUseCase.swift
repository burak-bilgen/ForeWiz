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
        try await notificationRepository.schedule(plans)
        return plans
    }
}
