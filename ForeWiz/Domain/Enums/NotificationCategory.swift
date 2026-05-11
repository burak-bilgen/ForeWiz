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
        case .morningBriefing: L10n.text("notification_morning_briefing")
        case .outfitSuggestion: L10n.text("notification_outfit")
        case .bestRunWindow: L10n.text("notification_best_run")
        case .avoidHeatWindow: L10n.text("notification_avoid_heat")
        case .rainWarning: L10n.text("notification_rain")
        case .windWarning: L10n.text("notification_wind")
        case .uvWarning: L10n.text("notification_uv")
        }
    }

    var localizedDescription: String {
        switch self {
        case .morningBriefing: L10n.text("notification_morning_briefing_desc")
        case .outfitSuggestion: L10n.text("notification_outfit_desc")
        case .bestRunWindow: L10n.text("notification_best_run_desc")
        case .avoidHeatWindow: L10n.text("notification_avoid_heat_desc")
        case .rainWarning: L10n.text("notification_rain_desc")
        case .windWarning: L10n.text("notification_wind_desc")
        case .uvWarning: L10n.text("notification_uv_desc")
        }
    }
}
