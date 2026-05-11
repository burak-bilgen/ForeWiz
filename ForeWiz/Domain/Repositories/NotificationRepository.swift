import Foundation

protocol NotificationRepository {
    func authorizationStatus() async -> NotificationAuthorizationStatus
    func requestAuthorization() async -> NotificationAuthorizationStatus
    func schedule(_ plans: [NotificationPlan]) async throws
    func cancelPendingSmartNotifications() async
}
