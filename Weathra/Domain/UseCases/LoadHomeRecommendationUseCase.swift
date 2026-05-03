import Foundation

struct HomeRecommendationResult: Equatable {
    let recommendation: DailyRecommendation
    let currentWeather: CurrentWeatherPoint
    let isUsingCachedWeather: Bool
    let warningMessage: String?
    let weatherFetchedAt: Date
    let attribution: WeatherAttributionInfo?
}

protocol LoadHomeRecommendationUseCase {
    func execute(forceRefresh: Bool) async throws -> HomeRecommendationResult
}
