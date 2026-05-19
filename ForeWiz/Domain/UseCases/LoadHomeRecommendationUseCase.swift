import Foundation

struct HomeRecommendationResult: Equatable {
    let recommendation: DailyRecommendation
    let currentWeather: CurrentWeatherPoint
    let minutePoints: [MinuteWeatherPoint]
    let hourlyPoints: [HourlyWeatherPoint]
    let dailyPoints: [DailyWeatherPoint]
    let alerts: [WeatherAlertInfo]
    let availability: WeatherAvailabilityInfo?
    let isUsingCachedWeather: Bool
    let usedLocation: LocationCoordinate?
    let warningMessage: String?
    let weatherFetchedAt: Date
    let attribution: WeatherAttributionInfo?
    let rankedCandidates: [RecommendationCandidate]
    let briefing: DailyWeatherBriefing?

    static func == (lhs: HomeRecommendationResult, rhs: HomeRecommendationResult) -> Bool {
        lhs.recommendation == rhs.recommendation &&
        lhs.isUsingCachedWeather == rhs.isUsingCachedWeather &&
        lhs.usedLocation == rhs.usedLocation &&
        lhs.warningMessage == rhs.warningMessage &&
        lhs.weatherFetchedAt == rhs.weatherFetchedAt
    }
}

protocol LoadHomeRecommendationUseCase {
    func execute(forceRefresh: Bool, targetLocation: LocationCoordinate?) async throws -> HomeRecommendationResult
}

extension LoadHomeRecommendationUseCase {
    func execute(forceRefresh: Bool) async throws -> HomeRecommendationResult {
        try await execute(forceRefresh: forceRefresh, targetLocation: nil)
    }
}
