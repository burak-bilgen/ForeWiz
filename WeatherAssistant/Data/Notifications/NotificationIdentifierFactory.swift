import Foundation

enum NotificationIdentifierFactory {
    static let smartPrefix = "smart."

    static func identifier(for plan: NotificationPlan) -> String {
        plan.id
    }
}
