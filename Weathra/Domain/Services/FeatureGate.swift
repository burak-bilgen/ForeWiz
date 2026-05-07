import Foundation

struct FeatureGate {
    static func isUnlocked(_ feature: PremiumFeature, tier: SubscriptionTier) -> Bool {
        if feature.isPremiumOnly == false {
            return true
        }
        return tier == .premium
    }
    
    static func premiumPrompt(for feature: PremiumFeature) -> String {
        L10n.text("premium_upgrade") + " — " + feature.localizedTitle
    }
}
