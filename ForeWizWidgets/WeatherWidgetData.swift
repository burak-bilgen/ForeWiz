import Foundation

/// Lightweight, codable model that the widget reads from UserDefaults (app group)
/// to display forecast information. The main app saves a matching JSON blob.
struct WeatherWidgetData: Codable, Equatable, Sendable {
    let locationName: String
    let currentTemperature: Double
    let currentConditionSymbol: String
    let currentConditionDescription: String
    let outdoorScore: Int
    let dailyForecasts: [WidgetDailyForecast]
    let lastUpdated: Date
    let attributionName: String

    static let appGroupSuiteName = "group.forewiz"
    static let userDefaultsKey = "com.forewiz.widget.weatherData"

    /// Loads the latest cached widget data from shared UserDefaults.
    static func load() -> WeatherWidgetData? {
        guard let defaults = UserDefaults(suiteName: Self.appGroupSuiteName),
              let data = defaults.data(forKey: Self.userDefaultsKey),
              let decoded = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        return decoded
    }
}

struct WidgetDailyForecast: Codable, Equatable, Sendable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)" }

    let date: Date
    let dayName: String
    let highTemp: Double
    let lowTemp: Double
    let conditionSymbol: String
    let outdoorScore: Int
    let isToday: Bool
    let precipitationChance: Double
}
