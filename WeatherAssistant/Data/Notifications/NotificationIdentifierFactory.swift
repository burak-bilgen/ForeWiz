import Foundation

enum NotificationIdentifierFactory {
    static func identifier(for plan: NotificationPlan) -> String {
        plan.id
    }
}
