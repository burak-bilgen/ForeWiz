import Foundation

struct NotificationPreference: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: NotificationCategory { category }

    let category: NotificationCategory
    var isEnabled: Bool
    var preferredTime: DateComponents?
}
