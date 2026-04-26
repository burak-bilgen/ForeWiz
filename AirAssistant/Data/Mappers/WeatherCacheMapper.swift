import Foundation

enum WeatherCacheMapper {
    static func domain(from stored: StoredWeatherSnapshot) -> WeatherSnapshot {
        stored.snapshot
    }
}
