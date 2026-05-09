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
    let symbolName: String?
    let isDaylight: Bool?
    let severeWeatherRisk: RiskLevel?

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
        severeWeatherRisk: RiskLevel?
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
    }
}
