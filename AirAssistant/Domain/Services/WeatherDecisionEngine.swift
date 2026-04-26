import Foundation

protocol WeatherDecisionEngine {
    func makeDailyRecommendation(
        snapshot: WeatherSnapshot,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> DailyRecommendation
}
