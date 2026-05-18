import Foundation

struct DefaultActivityWindowScoringEngine: ActivityWindowScoringEngine {
    func score(
        hour: HourlyWeatherPoint,
        activity: ActivityType,
        profile: UserComfortProfile,
        calendar: Calendar = .current
    ) -> WeatherScore {
        let hourOfDay = calendar.component(.hour, from: hour.date)

        guard isActiveHour(hourOfDay, profile: profile) else {
            return WeatherScore(rawValue: 0)
        }

        var score = 100
        let apparentTemperature = hour.apparentTemperatureCelsius
        let month = calendar.component(.month, from: hour.date)

        score -= goingOutTemperaturePenalty(apparentTemperature)
        score -= precipitationPenalty(hour)
        score -= windPenalty(hour.windSpeedKph)
        score -= humidityPenalty(hour.humidity, apparentTemperature: apparentTemperature)
        score -= uvPenalty(hour.uvIndex, hourOfDay: hourOfDay)

        if isHotSummerMidday(month: month, hour: hourOfDay, apparentTemperature: apparentTemperature) {
            score -= 14
        }

        if hour.isDaylight == false {
            score -= 15
        }

        if hourOfDay >= 22 || hourOfDay < 5 {
            score -= 20
        } else if hourOfDay >= 20 || hourOfDay < 6 {
            score -= 10
        }

        if let severeWeatherRisk = hour.severeWeatherRisk {
            score -= severeWeatherRisk == .extreme ? 90 : severeWeatherRisk.rawValue * 18
        }

        return WeatherScore(rawValue: score)
    }

    func bestWindow(
        for activity: ActivityType,
        hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar = .current
    ) -> ActivityRecommendation? {
        bestWindow(
            for: activity,
            hourly: hourly,
            profile: profile,
            now: now,
            calendar: calendar,
            avoidWindows: []
        )
    }

    func bestWindow(
        for activity: ActivityType,
        hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar = .current,
        avoidWindows: [AvoidWindowRecommendation]
    ) -> ActivityRecommendation? {
        let nextHours = hourly
            .filter { $0.date >= now }
            .sorted { $0.date < $1.date }
            .prefix(24)

        let scoredHours = nextHours.map { hour in
            (
                hour: hour,
                score: self.score(hour: hour, activity: activity, profile: profile, calendar: calendar)
            )
        }

        guard scoredHours.isEmpty == false else {
            return nil
        }

        var bestSlice: ArraySlice<(hour: HourlyWeatherPoint, score: WeatherScore)>?
        var bestAverage = -1

        for startIndex in scoredHours.indices {
            let windowSize = 3
            let endIndex = min(startIndex + windowSize, scoredHours.endIndex)
            let slice = scoredHours[startIndex..<endIndex]
            guard slice.isEmpty == false else { continue }

            guard let firstTime = slice.first?.hour.date,
                  let lastTime = slice.last?.hour.date else { continue }

            if overlapsAvoidWindows(start: firstTime, end: calendar.date(byAdding: .hour, value: 1, to: lastTime) ?? lastTime, avoidWindows: avoidWindows) {
                continue
            }

            let average = slice.map { $0.score.rawValue }.reduce(0, +) / slice.count

            if slice.allSatisfy({ $0.score.rawValue >= 60 }) && average > bestAverage {
                bestAverage = average
                bestSlice = slice
            }
        }

        guard
            let bestSlice,
            let firstHour = bestSlice.first?.hour,
            let lastHour = bestSlice.last?.hour
        else {
            return nil
        }

        let end = calendar.date(byAdding: .hour, value: 1, to: lastHour.date) ?? lastHour.date
        let window = TimeWindow(start: firstHour.date, end: end)
        let score = WeatherScore(rawValue: bestAverage)

        return ActivityRecommendation(
            activityType: activity,
            bestWindow: window,
            score: score,
            reason: reason(for: activity, score: score, window: window)
        )
    }

    // MARK: - Active hours guard

    private func isActiveHour(_ hourOfDay: Int, profile: UserComfortProfile) -> Bool {
        let endHour = profile.quietHours.map { Calendar.current.component(.hour, from: $0.start) } ?? 22

        let startHour = 7
        if endHour > startHour {
            return hourOfDay >= startHour && hourOfDay < endHour
        } else {
            return hourOfDay >= startHour || hourOfDay < endHour
        }
    }

    // MARK: - Avoid window overlap

    private func overlapsAvoidWindows(
        start: Date,
        end: Date,
        avoidWindows: [AvoidWindowRecommendation]
    ) -> Bool {
        for avoid in avoidWindows {
            if start < avoid.window.end && end > avoid.window.start {
                return true
            }
        }
        return false
    }

    // MARK: - Helpers

    private func goingOutTemperaturePenalty(_ temperature: Double) -> Int {
        switch temperature {
        case 12...28: 0
        case 6..<12, 28.01...31: 10
        case 31.01...35: 28
        case 35.01...: 48
        default: 22
        }
    }

    private func precipitationPenalty(_ hour: HourlyWeatherPoint) -> Int {
        let chance = hour.precipitationChance ?? 0
        let amount = hour.precipitationAmountMm ?? 0

        var penalty = 0.0
        if chance >= 0.7 || amount >= 2 {
            penalty += 36
        } else if chance >= 0.45 || amount >= 0.5 {
            penalty += 20
        } else if chance >= 0.25 {
            penalty += 8
        }

        return Int(penalty.rounded())
    }

    private func windPenalty(_ windSpeedKph: Double?) -> Int {
        let windSpeed = windSpeedKph ?? 0

        switch windSpeed {
        case 0..<20: return 0
        case 20..<30: return 8
        case 30..<45: return 22
        default: return 42
        }
    }

    private func humidityPenalty(
        _ humidity: Double?,
        apparentTemperature: Double
    ) -> Int {
        guard apparentTemperature >= 25 else { return 0 }
        let humidityValue = humidity ?? 0

        switch humidityValue {
        case 0.80...: return 16
        case 0.65..<0.80: return 8
        default: return 0
        }
    }

    private func uvPenalty(_ uvIndex: Int?, hourOfDay: Int) -> Int {
        guard (11...16).contains(hourOfDay) else { return 0 }
        let uv = uvIndex ?? 0

        switch uv {
        case 8...: return 24
        case 6...7: return 14
        default: return 0
        }
    }

    private func isHotSummerMidday(month: Int, hour: Int, apparentTemperature: Double) -> Bool {
        (6...9).contains(month) && (12...16).contains(hour) && apparentTemperature >= 28
    }

    private func reason(for activity: ActivityType, score: WeatherScore, window: TimeWindow) -> String {
        let time = window.shortDisplayText
        switch score.rawValue {
        case 80...:
            return String(format: L10n.text("reason_best_time"), activity.localizedTitle, time)
        case 60..<80:
            return String(format: L10n.text("reason_good_time"), activity.localizedTitle, time)
        default:
            return String(format: L10n.text("reason_moderate_time"), activity.localizedTitle, time)
        }
    }
}
