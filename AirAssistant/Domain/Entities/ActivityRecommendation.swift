import Foundation

struct ActivityRecommendation: Codable, Equatable, Identifiable, Sendable {
    var id: String { "\(activityType.rawValue)-\(bestWindow.id)" }

    let activityType: ActivityType
    let bestWindow: TimeWindow
    let score: WeatherScore
    let reason: String
}
