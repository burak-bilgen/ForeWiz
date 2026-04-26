import Foundation

final class SwiftDataWeatherCacheRepository: WeatherCacheRepository {
    private var latest: WeatherSnapshot?

    func loadLatest() async throws -> WeatherSnapshot? {
        latest
    }

    func save(_ snapshot: WeatherSnapshot) async throws {
        latest = snapshot
    }
}
