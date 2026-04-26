import Foundation

struct CurrentWeatherPoint: Codable, Equatable, Sendable {
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
}
