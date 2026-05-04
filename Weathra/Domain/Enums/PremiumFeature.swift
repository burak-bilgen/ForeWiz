import Foundation

enum PremiumFeature: String, CaseIterable, Identifiable, Codable, Sendable {
    case multipleLocations
    case sevenDayForecast
    case hourlyTimeline
    case premiumNotifications
    case widgetCustomization
    case advancedAnalytics
    
    var id: String { rawValue }
    
    var localizedTitle: String {
        switch self {
        case .multipleLocations: String(localized: "premium_feature_locations")
        case .sevenDayForecast: String(localized: "premium_feature_forecast")
        case .hourlyTimeline: String(localized: "premium_feature_hourly")
        case .premiumNotifications: String(localized: "premium_feature_notifications")
        case .widgetCustomization: String(localized: "premium_feature_widget")
        case .advancedAnalytics: String(localized: "premium_feature_analytics")
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .multipleLocations: String(localized: "premium_feature_locations_desc")
        case .sevenDayForecast: String(localized: "premium_feature_forecast_desc")
        case .hourlyTimeline: String(localized: "premium_feature_hourly_desc")
        case .premiumNotifications: String(localized: "premium_feature_notifications_desc")
        case .widgetCustomization: String(localized: "premium_feature_widget_desc")
        case .advancedAnalytics: String(localized: "premium_feature_analytics_desc")
        }
    }
    
    var systemImage: String {
        switch self {
        case .multipleLocations: "map.fill"
        case .sevenDayForecast: "calendar.badge.clock"
        case .hourlyTimeline: "chart.bar.fill"
        case .premiumNotifications: "bell.badge.waveform.fill"
        case .widgetCustomization: "square.grid.3x3.fill"
        case .advancedAnalytics: "chart.line.uptrend.xyaxis"
        }
    }
    
    var isPremiumOnly: Bool {
        switch self {
        case .multipleLocations, .sevenDayForecast, .hourlyTimeline, .premiumNotifications, .widgetCustomization, .advancedAnalytics:
            true
        }
    }
}
