import Foundation

struct OutfitRecommendationInput {
    let current: CurrentWeatherPoint
    let hourly: [HourlyWeatherPoint]
    let profile: UserComfortProfile
    let risks: [WeatherRisk]
    let avoidWindows: [AvoidWindowRecommendation]
    let calendar: Calendar
}

protocol OutfitDecisionEngine {
    func recommendOutfit(input: OutfitRecommendationInput) -> OutfitRecommendation
}
