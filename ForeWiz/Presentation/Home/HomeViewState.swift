import Foundation

struct HomeViewState: Equatable {
    let recommendation: DailyRecommendation
    let assistant: HomeAssistantViewState
    let currentWeather: HomeCurrentWeatherViewState
    let dailyForecasts: [DailyForecastItem]
    let hourlyScores: [HourlyScoreItem]
    let keyEvents: [DayKeyEvent]
    let lastUpdatedText: String
    let isUsingCachedWeather: Bool
    let warningMessage: String?
    let attribution: WeatherAttributionInfo?
}

struct HomeAssistantViewState: Equatable {
    let headline: String
    let summary: String
    let primaryActionTitle: String
    let primaryActionDetail: String
    let symbolName: String
    let tone: HomeAssistantTone
    let criticalAlert: HomeAssistantSignal?
}

struct HomeAssistantSignal: Equatable, Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let hint: String
    let tone: HomeAssistantTone
}

enum HomeAssistantTone: String, Equatable {
    case good
    case caution
    case danger
    case info
}

struct HourlyScoreItem: Equatable, Identifiable {
    var id: Date { date }

    let date: Date
    let hour: Int
    let score: Int
    let symbolName: String
    let temperatureText: String
    let precipitationChance: Double
}

struct HomeCurrentWeatherViewState: Equatable {
    let temperatureText: String
    let feelsLikeText: String
    let conditionText: String
    let symbolName: String
    let humidityText: String
    let windText: String
    let uvIndexText: String
    let highTempText: String
    let lowTempText: String
    let sunriseText: String?
    let sunsetText: String?
}
