import Foundation

enum NotificationContentFactory {
    static func titleAndBody(for plan: NotificationPlan) -> (title: String, body: String) {
        (sanitized(plan.title), sanitized(plan.body))
    }

    static private func sanitized(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
