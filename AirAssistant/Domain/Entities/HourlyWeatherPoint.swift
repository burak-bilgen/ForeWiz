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
}
