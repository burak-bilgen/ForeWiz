import Foundation

enum SubscriptionTier: String, Codable, CaseIterable, Sendable {
    case free
    case premium
    
    var localizedTitle: String {
        switch self {
        case .free: String(localized: "tier_free")
        case .premium: String(localized: "tier_premium")
        }
    }
}
