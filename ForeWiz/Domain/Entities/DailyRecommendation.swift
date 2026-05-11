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
    let isTomorrowsRecommendation: Bool
}

extension DailyRecommendation {
    static var placeholder: DailyRecommendation {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now
        let endTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now

        return DailyRecommendation(
            generatedAt: now,
            outdoorDecision: .good,
            outdoorScore: WeatherScore(rawValue: 85),
            bestOutdoorWindow: TimeWindow(start: startTime, end: endTime),
            bestActivityWindows: [],
            avoidWindows: [],
            outfit: OutfitRecommendation(
                title: L10n.text("outfit_light_and_comfortable"),
                items: [L10n.text("activity_running")],
                accessories: [],
                warning: nil
            ),
            risks: [],
            summaryText: L10n.text("decision_good"),
            explanation: "85/100",
            isTomorrowsRecommendation: false
        )
    }
}
