import Foundation

struct DailyWeatherPoint: Codable, Equatable, Identifiable, Sendable {
    var id: Date { date }

    let date: Date
    let highTemperatureCelsius: Double
    let lowTemperatureCelsius: Double
    let precipitationChance: Double?
    let uvIndex: Int?
    let conditionCode: String?
}
