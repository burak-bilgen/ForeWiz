import Foundation

enum NotificationIdentifierFactory {
    static let smartPrefix = "smart."
    static let legacySmartPrefix = "forewiz."

    static func identifier(for plan: NotificationPlan) -> String {
        smartPrefix + plan.id
    }
}
