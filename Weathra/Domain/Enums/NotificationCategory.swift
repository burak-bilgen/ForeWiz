import Foundation

enum NotificationCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case morningBriefing
    case outfitSuggestion
    case bestRunWindow
    case avoidHeatWindow
    case rainWarning
    case windWarning
    case uvWarning

    var localizedTitle: String {
        switch self {
        case .morningBriefing: String(localized: "notification_morning_briefing")
        case .outfitSuggestion: String(localized: "notification_outfit")
        case .bestRunWindow: String(localized: "notification_best_run")
        case .avoidHeatWindow: String(localized: "notification_avoid_heat")
        case .rainWarning: String(localized: "notification_rain")
        case .windWarning: String(localized: "notification_wind")
        case .uvWarning: String(localized: "notification_uv")
        }
    }

    var localizedDescription: String {
        switch self {
        case .morningBriefing: String(localized: "notification_morning_briefing_desc")
        case .outfitSuggestion: String(localized: "notification_outfit_desc")
        case .bestRunWindow: String(localized: "notification_best_run_desc")
        case .avoidHeatWindow: String(localized: "notification_avoid_heat_desc")
        case .rainWarning: String(localized: "notification_rain_desc")
        case .windWarning: String(localized: "notification_wind_desc")
        case .uvWarning: String(localized: "notification_uv_desc")
        }
    }
}
