import Foundation

enum NotificationCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case morningBriefing
    case keyEvent
    case weatherAlert

    var localizedTitle: String {
        switch self {
        case .morningBriefing: L10n.text("notification_morning_briefing")
        case .keyEvent: L10n.text("notification_key_event")
        case .weatherAlert: L10n.text("notification_weather_alert")
        }
    }

    var localizedDescription: String {
        switch self {
        case .morningBriefing: L10n.text("notification_morning_briefing_desc")
        case .keyEvent: L10n.text("notification_key_event_desc")
        case .weatherAlert: L10n.text("notification_weather_alert_desc")
        }
    }
}
