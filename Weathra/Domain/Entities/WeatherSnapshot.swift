import Foundation

struct WeatherAttributionInfo: Codable, Equatable, Identifiable, Sendable {
    let serviceName: String
    let legalPageURLString: String?
    let legalAttributionText: String?

    var id: String {
        [
            serviceName,
            legalPageURLString ?? "",
            legalAttributionText ?? ""
        ].joined(separator: "|")
    }
}

struct WeatherSnapshot: Codable, Equatable, Sendable {
    let location: LocationCoordinate
    let current: CurrentWeatherPoint
    let hourly: [HourlyWeatherPoint]
    let daily: [DailyWeatherPoint]
    let fetchedAt: Date
    let attribution: WeatherAttributionInfo?
}
