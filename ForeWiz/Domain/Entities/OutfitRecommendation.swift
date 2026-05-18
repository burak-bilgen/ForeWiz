import Foundation

struct OutfitRecommendation: Codable, Equatable, Sendable {
    let title: String
    let items: [String]
    let accessories: [String]
    let warning: String?
    /// Human-like conversational advice e.g. "Tişörtle çık ama akşama doğru üşüyebilirsin, yanına bir hırka al."
    let detailedAdvice: String?
}
