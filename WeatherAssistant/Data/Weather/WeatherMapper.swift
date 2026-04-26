import Foundation

enum WeatherMapper {
    static func unavailableUntilWeatherKitIsWired() -> AppError {
        .weatherUnavailable
    }
}
