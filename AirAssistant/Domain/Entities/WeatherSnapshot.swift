import Foundation

struct WeatherSnapshot: Codable, Equatable, Sendable {
    let location: LocationCoordinate
    let current: CurrentWeatherPoint
    let hourly: [HourlyWeatherPoint]
    let daily: [DailyWeatherPoint]
    let fetchedAt: Date
    let attribution: String?
}
