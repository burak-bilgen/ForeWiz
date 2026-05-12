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
        let apparentTemperature = adjustedTemperature(
            hour.apparentTemperatureCelsius,
            sensitivity: profile.temperatureSensitivity
        )
        let month = calendar.component(.month, from: hour.date)

        score -= temperaturePenalty(for: apparentTemperature, activity: activity)
        score -= precipitationPenalty(hour: hour, activity: activity)
        score -= windPenalty(hour.windSpeedKph, activity: activity)
        score -= humidityPenalty(hour.humidity, apparentTemperature: apparentTemperature, activity: activity)
        score -= uvPenalty(hour.uvIndex, hourOfDay: hourOfDay, activity: activity)

        if isHotSummerMidday(month: month, hour: hourOfDay, apparentTemperature: apparentTemperature) {
            score -= activity == .walking ? 14 : 22
        }

        if hour.isDaylight == false {
            if activity == .goingOutside {
                score -= 15
            } else {
                score -= 8
            }
        }

        if activity == .goingOutside {
            if hourOfDay >= 22 || hourOfDay < 5 {
                score -= 20
            } else if hourOfDay >= 20 || hourOfDay < 6 {
                score -= 10
            }
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
        let startHour = profile.wakeUpTime?.hour ?? 7
        let endHour = profile.quietHours.map { Calendar.current.component(.hour, from: $0.start) } ?? 22

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

    private func adjustedTemperature(_ temperature: Double, sensitivity: TemperatureSensitivity) -> Double {
        switch sensitivity {
        case .getsColdEasily:
            temperature - 2
        case .normal:
            temperature
        case .getsHotEasily:
            temperature + 2
        }
    }

    private func temperaturePenalty(for temperature: Double, activity: ActivityType) -> Int {
        switch activity {
        case .running:
            runningTemperaturePenalty(temperature)
        case .walking, .goingOutside:
            walkingTemperaturePenalty(temperature)
        case .cycling:
            cyclingTemperaturePenalty(temperature)
        }
    }

    private func runningTemperaturePenalty(_ temperature: Double) -> Int {
        switch temperature {
        case 8...22: 0
        case 4..<8, 22.01...26: 10
        case 26.01...30: 28
        case 30.01...34: 46
        case 34.01...: 68
        default: 24
        }
    }

    private func walkingTemperaturePenalty(_ temperature: Double) -> Int {
        switch temperature {
        case 12...28: 0
        case 6..<12, 28.01...31: 10
        case 31.01...35: 28
        case 35.01...: 48
        default: 22
        }
    }

    private func cyclingTemperaturePenalty(_ temperature: Double) -> Int {
        switch temperature {
        case 10...24: 0
        case 5..<10, 24.01...28: 12
        case 28.01...32: 30
        case 32.01...: 54
        default: 24
        }
    }

    private func precipitationPenalty(hour: HourlyWeatherPoint, activity: ActivityType) -> Int {
        let chance = hour.precipitationChance ?? 0
        let amount = hour.precipitationAmountMm ?? 0
        let activityMultiplier: Double = activity == .walking ? 0.75 : 1

        var penalty = 0.0
        if chance >= 0.7 || amount >= 2 {
            penalty += 36
        } else if chance >= 0.45 || amount >= 0.5 {
            penalty += 20
        } else if chance >= 0.25 {
            penalty += 8
        }

        return Int((penalty * activityMultiplier).rounded())
    }

    private func windPenalty(_ windSpeedKph: Double?, activity: ActivityType) -> Int {
        let windSpeed = windSpeedKph ?? 0
        let cyclingMultiplier = activity == .cycling ? 1.55 : 1

        switch windSpeed {
        case 0..<20: return 0
        case 20..<30: return Int((8 * cyclingMultiplier).rounded())
        case 30..<45: return Int((22 * cyclingMultiplier).rounded())
        default: return Int((42 * cyclingMultiplier).rounded())
        }
    }

    private func humidityPenalty(
        _ humidity: Double?,
        apparentTemperature: Double,
        activity: ActivityType
    ) -> Int {
        guard apparentTemperature >= 25 else { return 0 }
        let humidityValue = humidity ?? 0
        let multiplier = activity == .running ? 1.3 : 1

        switch humidityValue {
        case 0.80...: return Int((16 * multiplier).rounded())
        case 0.65..<0.80: return Int((8 * multiplier).rounded())
        default: return 0
        }
    }

    private func uvPenalty(_ uvIndex: Int?, hourOfDay: Int, activity: ActivityType) -> Int {
        guard (11...16).contains(hourOfDay) else { return 0 }
        let uv = uvIndex ?? 0
        let multiplier = activity == .running ? 1.15 : 1

        switch uv {
        case 8...: return Int((24 * multiplier).rounded())
        case 6...7: return Int((14 * multiplier).rounded())
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