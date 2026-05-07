import Foundation

enum SubscriptionTier: String, Codable, CaseIterable, Sendable {
    case free
    case premium
    
    var localizedTitle: String {
        switch self {
        case .free: L10n.text("tier_free")
        case .premium: L10n.text("tier_premium")
        }
    }
}
