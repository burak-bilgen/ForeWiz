import Foundation

struct FeatureGate {
    static func isUnlocked(_ feature: Any, tier: Any) -> Bool {
        true
    }

    static func premiumPrompt(for feature: Any) -> String {
        ""
    }
}
