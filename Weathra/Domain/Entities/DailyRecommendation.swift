import Foundation

struct DailyRecommendation: Codable, Equatable, Sendable {
    let generatedAt: Date
    let outdoorDecision: OutdoorDecision
    let outdoorScore: WeatherScore
    let bestOutdoorWindow: TimeWindow?
    let bestActivityWindows: [ActivityRecommendation]
    let avoidWindows: [AvoidWindowRecommendation]
    let outfit: OutfitRecommendation
    let risks: [WeatherRisk]
    let summaryText: String
    let explanation: String
}
