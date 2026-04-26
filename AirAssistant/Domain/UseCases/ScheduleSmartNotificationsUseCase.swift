import Foundation

protocol ScheduleSmartNotificationsUseCase {
    func execute(recommendation: DailyRecommendation, profile: UserComfortProfile) async throws -> [NotificationPlan]
}
