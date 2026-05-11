import Foundation

struct WeatherRisk: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String { "\(type.rawValue)-\(severity.rawValue)-\(title)" }

    let type: WeatherRiskType
    let severity: RiskLevel
    let title: String
    let message: String
}
