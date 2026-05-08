import Foundation

struct DailyForecastItem: Identifiable, Equatable, Sendable {
    let id = UUID()
    let dayName: String
    let date: Date
    let highTemp: Double
    let lowTemp: Double
    let conditionSymbol: String
    let outdoorScore: Int
    let outdoorDecision: OutdoorDecision
    let isToday: Bool
    let precipitationChance: Double
}
