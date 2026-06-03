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

    func bestWindow(
        for activity: ActivityType,
        hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar,
        avoidWindows: [AvoidWindowRecommendation]
    ) -> ActivityRecommendation?

    func scoreWindow(
        start: Date,
        end: Date,
        activityType: ActivityType?
    ) async -> WeatherScore

    func bestWindows(
        in timeSlots: [TimeWindow],
        for activityType: ActivityType?
    ) -> [ActivityRecommendation]
}
