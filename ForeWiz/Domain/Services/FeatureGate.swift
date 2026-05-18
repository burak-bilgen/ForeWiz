import Foundation

enum PremiumTier: String, Codable, Sendable {
    case free
    case premium

    var rank: Int {
        switch self {
        case .free: 0
        case .premium: 1
        }
    }
}

struct FeatureGate {
    static var currentTier: PremiumTier = .premium

    static func isUnlocked(_ feature: Feature, tier: PremiumTier = currentTier) -> Bool {
        true
    }

    static func premiumPrompt(for feature: Feature) -> String {
        ""
    }
}

enum Feature: String, CaseIterable, Sendable {
    case dailyForecast
    case hourlyForecast
    case insights
    case severeWeatherAlerts
    case removeAds
    case widgets
    case fourteenDayForecast
    
    var requiredTier: PremiumTier {
        switch self {
        case .dailyForecast, .hourlyForecast:
            return .free
        case .insights, .severeWeatherAlerts, .removeAds, .widgets, .fourteenDayForecast:
            return .premium
        }
    }
}
