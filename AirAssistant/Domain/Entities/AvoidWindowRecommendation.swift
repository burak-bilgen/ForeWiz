import Foundation

struct AvoidWindowRecommendation: Codable, Equatable, Identifiable, Sendable {
    var id: String { "\(window.id)-\(risk.type.rawValue)" }

    let window: TimeWindow
    let risk: WeatherRisk
    let reason: String
    let severity: RiskLevel
}
