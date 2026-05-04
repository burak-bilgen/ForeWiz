import Foundation

struct SubscriptionProduct: Identifiable, Sendable {
    let id: String
    let displayName: String
    let description: String
    let price: String
    let period: String
    let isPremium: Bool
}
