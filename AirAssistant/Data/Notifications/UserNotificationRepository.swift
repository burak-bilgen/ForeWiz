import Foundation

final class UserNotificationRepository: NotificationRepository {
    func requestAuthorization() async -> NotificationAuthorizationStatus {
        .notDetermined
    }

    func schedule(_ plans: [NotificationPlan]) async throws {
        _ = plans
    }

    func cancelPendingSmartNotifications() async {}
}
