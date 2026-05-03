import Foundation

protocol WeatherRepository {
    func fetchWeather(for location: LocationCoordinate) async throws -> WeatherSnapshot
}
