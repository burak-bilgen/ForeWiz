import Foundation

struct OutfitRecommendation: Codable, Equatable, Sendable {
    let title: String
    let items: [String]
    let accessories: [String]
    let warning: String?

    let detailedAdvice: String?
}
