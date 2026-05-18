import Foundation

enum NotificationCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case morningBriefing
    case outfitSuggestion
    case bestRunWindow
    case avoidHeatWindow
    case rainWarning
    case windWarning
    case uvWarning
    case stormWarning
    case coldWarning
    case humidityWarning
    case poorComfortWarning

    var localizedTitle: String {
        switch self {
        case .morningBriefing: L10n.text("notification_morning_briefing")
        case .outfitSuggestion: L10n.text("notification_outfit")
        case .bestRunWindow: L10n.text("notification_best_run")
        case .avoidHeatWindow: L10n.text("notification_avoid_heat")
        case .rainWarning: L10n.text("notification_rain")
        case .windWarning: L10n.text("notification_wind")
        case .uvWarning: L10n.text("notification_uv")
        case .stormWarning: L10n.text("notification_storm_warning")
        case .coldWarning: L10n.text("notification_cold_warning")
        case .humidityWarning: L10n.text("notification_humidity_warning")
        case .poorComfortWarning: L10n.text("notification_poor_comfort_warning")
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
        case .stormWarning: L10n.text("notification_storm_warning_desc")
        case .coldWarning: L10n.text("notification_cold_warning_desc")
        case .humidityWarning: L10n.text("notification_humidity_warning_desc")
        case .poorComfortWarning: L10n.text("notification_poor_comfort_warning_desc")
        }
    }
}
