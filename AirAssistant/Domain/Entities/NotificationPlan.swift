import Foundation

struct NotificationPlan: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let category: NotificationCategory
    let fireDate: Date
    let title: String
    let body: String
    let priority: Int
    let reason: String
}
