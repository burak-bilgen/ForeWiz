import Foundation

enum PremiumFeature: String, CaseIterable, Identifiable, Codable, Sendable {
    case removeAds
    case fourteenDayForecast
    case advancedAnalytics
    case appleWatchCompanion

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .removeAds: L10n.text("premium_remove_ads")
        case .fourteenDayForecast: L10n.text("premium_feature_forecast_14day")
        case .advancedAnalytics: L10n.text("premium_feature_analytics")
        case .appleWatchCompanion: L10n.text("premium_feature_watch")
        }
    }

    var localizedDescription: String {
        switch self {
        case .removeAds: L10n.text("premium_remove_ads_desc")
        case .fourteenDayForecast: L10n.text("premium_feature_forecast_14day_desc")
        case .advancedAnalytics: L10n.text("premium_feature_analytics_desc")
        case .appleWatchCompanion: L10n.text("premium_feature_watch_desc")
        }
    }

    var systemImage: String {
        switch self {
        case .removeAds: "xmark.square.fill"
        case .fourteenDayForecast: "calendar.badge.explosionmark"
        case .advancedAnalytics: "chart.line.uptrend.xyaxis"
        case .appleWatchCompanion: "applewatch.watchface"
        }
    }

    var isPremiumOnly: Bool {
        true
    }

    var displayPriority: Int {
        switch self {
        case .removeAds: 0
        case .fourteenDayForecast: 1
        case .advancedAnalytics: 2
        case .appleWatchCompanion: 3
        }
    }
}
