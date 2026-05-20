import Foundation

protocol ScheduleSmartNotificationsUseCase {
    func execute(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        hourlyPoints: [HourlyWeatherPoint]
    ) async throws -> [NotificationPlan]
}
