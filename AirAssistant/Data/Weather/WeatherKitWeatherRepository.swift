import Foundation

final class WeatherKitWeatherRepository: WeatherRepository {
    func fetchWeather(for location: LocationCoordinate) async throws -> WeatherSnapshot {
        throw AppError.weatherUnavailable
    }
}
