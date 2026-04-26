import Foundation

protocol RefreshWeatherUseCase {
    func execute(for location: LocationCoordinate) async throws -> WeatherSnapshot
}
