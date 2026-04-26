import Foundation

protocol GetBestActivityWindowUseCase {
    func execute(
        activity: ActivityType,
        snapshot: WeatherSnapshot,
        profile: UserComfortProfile
    ) async throws -> ActivityRecommendation?
}
