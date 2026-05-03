import Foundation

struct HomeViewState: Equatable {
    let recommendation: DailyRecommendation
    let currentWeather: HomeCurrentWeatherViewState
    let lastUpdatedText: String
    let isUsingCachedWeather: Bool
    let warningMessage: String?
    let attribution: WeatherAttributionInfo?
}

struct HomeCurrentWeatherViewState: Equatable {
    let temperatureText: String
    let feelsLikeText: String
    let conditionText: String
    let symbolName: String
}
