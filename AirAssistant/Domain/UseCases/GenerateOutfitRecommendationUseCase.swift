import Foundation

protocol GenerateOutfitRecommendationUseCase {
    func execute(snapshot: WeatherSnapshot, profile: UserComfortProfile) async throws -> OutfitRecommendation
}
