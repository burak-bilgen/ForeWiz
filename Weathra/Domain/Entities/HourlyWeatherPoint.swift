import Foundation

struct HourlyWeatherPoint: Codable, Equatable, Identifiable, Sendable {
    var id: Date { date }

    let date: Date
    let temperatureCelsius: Double
    let apparentTemperatureCelsius: Double
    let humidity: Double?
    let windSpeedKph: Double?
    let precipitationChance: Double?
    let precipitationAmountMm: Double?
    let uvIndex: Int?
    let conditionCode: String?
    let isDaylight: Bool?
    let severeWeatherRisk: RiskLevel?
    let pollenLevel: PollenLevel?
    let airQualityIndex: AirQualityIndex?
    let pm25Level: Pm25Level?
}

enum PollenLevel: String, Codable, Sendable {
    case none
    case veryLow
    case low
    case moderate
    case high
    case veryHigh

    var severity: Int {
        switch self {
        case .none: return 0
        case .veryLow: return 1
        case .low: return 2
        case .moderate: return 3
        case .high: return 4
        case .veryHigh: return 5
        }
    }
}

enum AirQualityIndex: String, Codable, Sendable {
    case good
    case moderate
    case unhealthySensitive
    case unhealthy
    case veryUnhealthy
    case hazardous

    var severity: Int {
        switch self {
        case .good: return 1
        case .moderate: return 2
        case .unhealthySensitive: return 3
        case .unhealthy: return 4
        case .veryUnhealthy: return 5
        case .hazardous: return 6
        }
    }
}

enum Pm25Level: String, Codable, Sendable {
    case good
    case moderate
    case unhealthySensitive
    case unhealthy
    case veryUnhealthy
    case hazardous

    var severity: Int {
        switch self {
        case .good: return 1
        case .moderate: return 2
        case .unhealthySensitive: return 3
        case .unhealthy: return 4
        case .veryUnhealthy: return 5
        case .hazardous: return 6
        }
    }
}
