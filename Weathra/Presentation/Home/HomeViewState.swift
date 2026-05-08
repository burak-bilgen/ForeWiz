import Foundation

struct HomeViewState: Equatable {
    let recommendation: DailyRecommendation
    let currentWeather: HomeCurrentWeatherViewState
    let dailyForecasts: [DailyForecastItem]
    let hourlyScores: [HourlyScoreItem]
    let lastUpdatedText: String
    let isUsingCachedWeather: Bool
    let warningMessage: String?
    let attribution: WeatherAttributionInfo?
}

struct HourlyScoreItem: Equatable {
    let hour: Int
    let score: Int
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
}
