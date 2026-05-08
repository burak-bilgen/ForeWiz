import Foundation
import UserNotifications
import os

final class UserNotificationRepository: NotificationRepository {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        return map(settings.authorizationStatus)
    }

    func requestAuthorization() async -> NotificationAuthorizationStatus {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
            let granted = try await center.requestAuthorization(options: options)
            if granted {
                return .authorized
            }

            let settings = await center.notificationSettings()
            return map(settings.authorizationStatus)
        } catch {
            AppLogger.notifications.error("Failed to request notification authorization: \(error.localizedDescription)")
            return .denied
        }
    }

    func schedule(_ plans: [NotificationPlan]) async throws {
        await cancelPendingSmartNotifications()

        for plan in plans {
            let content = UNMutableNotificationContent()
            let titleAndBody = NotificationContentFactory.titleAndBody(for: plan)
            content.title = titleAndBody.title
            content.body = titleAndBody.body
            content.sound = .default
            content.badge = 1

            // Category identifier'e göre category set et
            content.categoryIdentifier = plan.category.rawValue

            // Priority'e göre interruption level set et
            if plan.priority >= 90 {
                content.interruptionLevel = .critical
            } else if plan.priority >= 70 {
                content.interruptionLevel = .timeSensitive
            } else {
                content.interruptionLevel = .passive
            }

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: plan.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: NotificationIdentifierFactory.identifier(for: plan),
                content: content,
                trigger: trigger
            )

            try await center.add(request)
        }
    }

    func cancelPendingSmartNotifications() async {
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(NotificationIdentifierFactory.smartPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func map(_ status: UNAuthorizationStatus) -> NotificationAuthorizationStatus {
        switch status {
        case .authorized, .ephemeral:
            .authorized
        case .provisional:
            .provisional
        case .denied:
            .denied
        case .notDetermined:
            .notDetermined
        @unknown default:
            .denied
        }
    }
}
