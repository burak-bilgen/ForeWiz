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
    private static let premiumTierKey = "forewiz.premiumTier"
    
    static var currentTier: PremiumTier {
        get {
            guard let raw = UserDefaults.standard.string(forKey: premiumTierKey),
                  let tier = PremiumTier(rawValue: raw) else {
                return .free
            }
            return tier
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: premiumTierKey)
        }
    }
    
    static func isUnlocked(_ feature: Feature, tier: PremiumTier = currentTier) -> Bool {
        tier.rank >= feature.requiredTier.rank
    }
    
    static func premiumPrompt(for feature: Feature) -> String {
        "This is a Premium feature."
    }
}

enum Feature: String, CaseIterable, Sendable {
    case dailyForecast
    case hourlyForecast
    case insights
    case severeWeatherAlerts
    case removeAds
    case widgets
    
    var requiredTier: PremiumTier {
        switch self {
        case .dailyForecast, .hourlyForecast:
            return .free
        case .insights, .severeWeatherAlerts, .removeAds, .widgets:
            return .premium
        }
    }
}
