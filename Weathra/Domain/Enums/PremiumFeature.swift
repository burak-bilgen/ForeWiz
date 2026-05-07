import Foundation

enum PremiumFeature: String, CaseIterable, Identifiable, Codable, Sendable {
    case multipleLocations
    case fourteenDayForecast
    case hourlyTimeline
    case severeWeatherAlerts
    case widgetCustomization
    case advancedAnalytics
    case appleWatchCompanion

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .multipleLocations: String(localized: "premium_feature_locations")
        case .fourteenDayForecast: String(localized: "premium_feature_forecast_14day")
        case .hourlyTimeline: String(localized: "premium_feature_hourly")
        case .severeWeatherAlerts: String(localized: "premium_feature_alerts")
        case .widgetCustomization: String(localized: "premium_feature_widget")
        case .advancedAnalytics: String(localized: "premium_feature_analytics")
        case .appleWatchCompanion: String(localized: "premium_feature_watch")
        }
    }

    var localizedDescription: String {
        switch self {
        case .multipleLocations: String(localized: "premium_feature_locations_desc")
        case .fourteenDayForecast: String(localized: "premium_feature_forecast_14day_desc")
        case .hourlyTimeline: String(localized: "premium_feature_hourly_desc")
        case .severeWeatherAlerts: String(localized: "premium_feature_alerts_desc")
        case .widgetCustomization: String(localized: "premium_feature_widget_desc")
        case .advancedAnalytics: String(localized: "premium_feature_analytics_desc")
        case .appleWatchCompanion: String(localized: "premium_feature_watch_desc")
        }
    }

    var systemImage: String {
        switch self {
        case .multipleLocations: "map.fill"
        case .fourteenDayForecast: "calendar.badge.explosionmark"
        case .hourlyTimeline: "chart.bar.fill"
        case .severeWeatherAlerts: "exclamationmark.octagon.fill"
        case .widgetCustomization: "square.grid.3x3.fill"
        case .advancedAnalytics: "chart.line.uptrend.xyaxis"
        case .appleWatchCompanion: "applewatch.watchface"
        }
    }

    var isPremiumOnly: Bool {
        switch self {
        case .multipleLocations, .fourteenDayForecast, .hourlyTimeline,
             .severeWeatherAlerts, .widgetCustomization, .advancedAnalytics, .appleWatchCompanion:
            true
        }
    }

    var displayPriority: Int {
        switch self {
        case .fourteenDayForecast: 1
        case .multipleLocations: 2
        case .severeWeatherAlerts: 3
        case .hourlyTimeline: 4
        case .widgetCustomization: 5
        case .advancedAnalytics: 6
        case .appleWatchCompanion: 7
        }
    }
}
