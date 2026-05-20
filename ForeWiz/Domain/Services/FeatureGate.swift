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
    /// Varsayılan .free — premium satın alındığında .premium olur.
    /// ForeWizApp.start() ve PremiumManager satın alma akışı bu değeri yönetir.
    static var currentTier: PremiumTier = .free

    static func isUnlocked(_ feature: Feature, tier: PremiumTier = currentTier) -> Bool {
        tier.rank >= feature.requiredTier.rank
    }

    static func premiumPrompt(for feature: Feature) -> String {
        switch feature {
        case .dailyForecast, .hourlyForecast:
            return ""
        default:
            return L10n.text("premium_prompt_generic")
        }
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
