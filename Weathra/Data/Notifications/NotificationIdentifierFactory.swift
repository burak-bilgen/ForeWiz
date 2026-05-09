import Foundation

enum NotificationIdentifierFactory {
    static let smartPrefix = "smart."
    static let legacySmartPrefix = "weathra."

    static func identifier(for plan: NotificationPlan) -> String {
        smartPrefix + plan.id
    }
}
