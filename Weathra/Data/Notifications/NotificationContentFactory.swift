import Foundation

enum NotificationContentFactory {
    static func titleAndBody(for plan: NotificationPlan) -> (title: String, body: String) {
        (plan.title, plan.body)
    }
}
