import Foundation

struct DailyWeatherPoint: Codable, Equatable, Identifiable, Sendable {
    var id: Date { date }

    let date: Date
    let highTemperatureCelsius: Double
    let lowTemperatureCelsius: Double
    let precipitationChance: Double?
    let uvIndex: Int?
    let conditionCode: String?
    let symbolName: String?
    let sunrise: Date?
    let sunset: Date?

    init(
        date: Date,
        highTemperatureCelsius: Double,
        lowTemperatureCelsius: Double,
        precipitationChance: Double?,
        uvIndex: Int?,
        conditionCode: String?,
        symbolName: String? = nil,
        sunrise: Date? = nil,
        sunset: Date? = nil
    ) {
        self.date = date
        self.highTemperatureCelsius = highTemperatureCelsius
        self.lowTemperatureCelsius = lowTemperatureCelsius
        self.precipitationChance = precipitationChance
        self.uvIndex = uvIndex
        self.conditionCode = conditionCode
        self.symbolName = symbolName
        self.sunrise = sunrise
        self.sunset = sunset
    }
}
