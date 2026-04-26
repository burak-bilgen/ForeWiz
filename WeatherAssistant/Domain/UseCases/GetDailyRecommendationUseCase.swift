import Foundation

protocol GetDailyRecommendationUseCase {
    func execute(snapshot: WeatherSnapshot, profile: UserComfortProfile) async throws -> DailyRecommendation
}
