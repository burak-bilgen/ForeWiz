import Foundation

protocol ActivityWindowScoringEngine {
    func score(
        hour: HourlyWeatherPoint,
        activity: ActivityType,
        profile: UserComfortProfile,
        calendar: Calendar
    ) -> WeatherScore

    func bestWindow(
        for activity: ActivityType,
        hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> ActivityRecommendation?
}
