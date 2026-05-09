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
    let symbolName: String?
    let isDaylight: Bool?
    let severeWeatherRisk: RiskLevel?
    let pollenLevel: PollenLevel?
    let airQualityIndex: AirQualityIndex?
    let pm25Level: Pm25Level?

    init(
        date: Date,
        temperatureCelsius: Double,
        apparentTemperatureCelsius: Double,
        humidity: Double?,
        windSpeedKph: Double?,
        precipitationChance: Double?,
        precipitationAmountMm: Double?,
        uvIndex: Int?,
        conditionCode: String?,
        symbolName: String? = nil,
        isDaylight: Bool?,
        severeWeatherRisk: RiskLevel?,
        pollenLevel: PollenLevel?,
        airQualityIndex: AirQualityIndex?,
        pm25Level: Pm25Level?
    ) {
        self.date = date
        self.temperatureCelsius = temperatureCelsius
        self.apparentTemperatureCelsius = apparentTemperatureCelsius
        self.humidity = humidity
        self.windSpeedKph = windSpeedKph
        self.precipitationChance = precipitationChance
        self.precipitationAmountMm = precipitationAmountMm
        self.uvIndex = uvIndex
        self.conditionCode = conditionCode
        self.symbolName = symbolName
        self.isDaylight = isDaylight
        self.severeWeatherRisk = severeWeatherRisk
        self.pollenLevel = pollenLevel
        self.airQualityIndex = airQualityIndex
        self.pm25Level = pm25Level
    }
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
