import Foundation

final class SwiftDataWeatherCacheRepository: WeatherCacheRepository {
    private enum Key {
        static let latestWeather = "weathra.latestWeather.v1"
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadLatest() async throws -> WeatherSnapshot? {
        guard let data = userDefaults.data(forKey: Key.latestWeather) else {
            return nil
        }

        do {
            return try decoder.decode(StoredWeatherSnapshot.self, from: data).snapshot
        } catch {
            throw AppError.cacheUnavailable
        }
    }

    func save(_ snapshot: WeatherSnapshot) async throws {
        do {
            let data = try encoder.encode(StoredWeatherSnapshot(snapshot: snapshot))
            userDefaults.set(data, forKey: Key.latestWeather)
        } catch {
            throw AppError.cacheUnavailable
        }
    }
}
