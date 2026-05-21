import Foundation

struct DefaultActivityWindowScoringEngine: ActivityWindowScoringEngine {
    
    // MARK: - Scoring Constants
    
    private enum ScoringPenalties {
        static let hotSummerMidday = 20
        static let nighttime = 15
        static let lateNight = 20
        static let evening = 10
        static let severeWeatherExtreme = 90
        static let severeWeatherMultiplier = 18
        static let defaultStartHour = 7
        static let defaultEndHour = 21
        static let bestWindowSize = 3
        static let minimumAcceptableScore = 60
    }
    
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
            score -= ScoringPenalties.hotSummerMidday
        }

        if hour.isDaylight == false {
            score -= ScoringPenalties.nighttime
        }

        if hourOfDay >= 21 || hourOfDay < 5 {
            score -= ScoringPenalties.lateNight
        } else if hourOfDay >= 20 || hourOfDay < 6 {
            score -= ScoringPenalties.evening
        }

        if let severeWeatherRisk = hour.severeWeatherRisk {
            score -= severeWeatherRisk == .extreme ? ScoringPenalties.severeWeatherExtreme : severeWeatherRisk.rawValue * ScoringPenalties.severeWeatherMultiplier
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
            let windowSize = ScoringPenalties.bestWindowSize
            let endIndex = min(startIndex + windowSize, scoredHours.endIndex)
            let slice = scoredHours[startIndex..<endIndex]
            guard slice.isEmpty == false else { continue }

            guard let firstTime = slice.first?.hour.date,
                  let lastTime = slice.last?.hour.date else { continue }

            if overlapsAvoidWindows(start: firstTime, end: calendar.date(byAdding: .hour, value: 1, to: lastTime) ?? lastTime, avoidWindows: avoidWindows) {
                continue
            }

            let average = slice.map { $0.score.rawValue }.reduce(0, +) / slice.count

            if slice.allSatisfy({ $0.score.rawValue >= ScoringPenalties.minimumAcceptableScore }) && average > bestAverage {
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
        let endHour = profile.quietHours.map { Calendar.current.component(.hour, from: $0.start) } ?? ScoringPenalties.defaultEndHour
        let startHour = ScoringPenalties.defaultStartHour
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

    /// Küresel ısınma odaklı ısı cezası — yüksek sıcaklıklar artık çok daha ağır cezalandırılıyor.
    ///   < 12°C:  soğuk (22)
    ///   12-26°C: ideal (0)
    ///   26-29°C: sıcaklık başlangıcı (15)
    ///   29-32°C: rahatsız (35)
    ///   32-35°C: tehlikeli (50)
    ///   35-38°C: çok tehlikeli (65)
    ///   > 38°C:  ekstrem (85)
    private func goingOutTemperaturePenalty(_ temperature: Double) -> Int {
        switch temperature {
        case 12...26: 0
        case 26.01...29: 15
        case 29.01...32: 35
        case 32.01...35: 50
        case 35.01...38: 65
        case 38.01...: 85
        case 6..<12: 10
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

    /// Nem cezası — ısı + nem kombinasyonu (Heat Index / Humidex) çok daha agresif.
    /// Yüksek sıcaklıkta nem, hissedilen sıcaklığı dramatik artırır.
    private func humidityPenalty(
        _ humidity: Double?,
        apparentTemperature: Double
    ) -> Int {
        let humidityValue = humidity ?? 0
        guard apparentTemperature >= 22 else { return 0 }

        // Heat index yaklaşımı: sıcaklık arttıkça nem cezası katlanır
        let basePenalty: Int
        switch humidityValue {
        case 0.80...: basePenalty = 20
        case 0.65..<0.80: basePenalty = 12
        case 0.50..<0.65: basePenalty = 6
        default: basePenalty = 0
        }

        // Sıcaklık yükseldikçe nem cezası çarpanı artar
        let multiplier: Double
        switch apparentTemperature {
        case 35...: multiplier = 2.0
        case 30..<35: multiplier = 1.5
        case 25..<30: multiplier = 1.0
        default: multiplier = 1.0
        }

        return Int(Double(basePenalty) * multiplier)
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

    /// Sıcak mevsim genişletildi: Mayıs-Ekim (5-10) arası, 26°C+ başlangıç
    /// Küresel ısınmayla sıcak mevsim uzadı ve erken başlıyor.
    private func isHotSummerMidday(month: Int, hour: Int, apparentTemperature: Double) -> Bool {
        (5...10).contains(month) && (11...17).contains(hour) && apparentTemperature >= 26
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
