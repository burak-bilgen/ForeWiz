import Foundation

struct HomeRecommendationResult: Equatable {
    let recommendation: DailyRecommendation
    let isUsingCachedWeather: Bool
    let warningMessage: String?
}

protocol LoadHomeRecommendationUseCase {
    func execute(forceRefresh: Bool) async throws -> HomeRecommendationResult
}
