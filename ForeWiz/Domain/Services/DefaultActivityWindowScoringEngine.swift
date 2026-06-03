import Foundation

struct DefaultActivityWindowScoringEngine: ActivityWindowScoringEngine {

    // MARK: - Dependencies

    private let weatherCacheRepository: WeatherCacheRepository?
    private let defaultProfile: UserComfortProfile

    init(
        weatherCacheRepository: WeatherCacheRepository? = nil,
        defaultProfile: UserComfortProfile = .default
    ) {
        self.weatherCacheRepository = weatherCacheRepository
        self.defaultProfile = defaultProfile
    }

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

        let adjustedTemp = apparentTemperature + profile.temperatureOffset
        let adjustedWind = (hour.windSpeedKph ?? 0) * profile.windSensitivityMultiplier

        score -= goingOutTemperaturePenalty(adjustedTemp)
        score -= precipitationPenalty(hour)
        score -= windPenalty(adjustedWind)
        score -= humidityPenalty(hour.humidity, apparentTemperature: adjustedTemp)
        score -= uvPenalty(hour.uvIndex, hourOfDay: hourOfDay)

        if isHotSummerMidday(month: month, hour: hourOfDay, apparentTemperature: adjustedTemp) {
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

        score -= activitySpecificPenalty(for: activity, hour: hour, hourOfDay: hourOfDay, calendar: calendar)

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

    // MARK: - New Protocol Methods

    func scoreWindow(
        start: Date,
        end: Date,
        activityType: ActivityType?
    ) async -> WeatherScore {
        let activity = activityType ?? .goingOutside
        let calendar = Calendar.current

        if let repo = weatherCacheRepository,
           let snapshot = try? await repo.loadLatest() {
            let hoursInWindow = snapshot.hourly.filter { $0.date >= start && $0.date < end }
            if !hoursInWindow.isEmpty {
                let scores = hoursInWindow.map {
                    score(hour: $0, activity: activity, profile: defaultProfile, calendar: calendar)
                }
                let avg = scores.map(\.rawValue).reduce(0, +) / scores.count
                return WeatherScore(rawValue: avg)
            }
        }

        return seasonalScore(for: activity, start: start, end: end)
    }

    func bestWindows(
        in timeSlots: [TimeWindow],
        for activityType: ActivityType?
    ) -> [ActivityRecommendation] {
        let activity = activityType ?? .goingOutside
        let calendar = Calendar.current

        let recommendations: [ActivityRecommendation] = timeSlots.compactMap { window in
            let startHour = calendar.component(.hour, from: window.start)
            guard isActiveHour(startHour, profile: defaultProfile) else { return nil }

            let month = calendar.component(.month, from: window.start)
            let isDaylight = (6...20).contains(startHour)

            let dummyHour = HourlyWeatherPoint(
                date: window.start,
                temperatureCelsius: 20,
                apparentTemperatureCelsius: 20,
                humidity: 0.50,
                windSpeedKph: 10,
                precipitationChance: 0.05,
                precipitationAmountMm: 0,
                uvIndex: uvEstimate(for: startHour, month: month),
                conditionCode: nil,
                isDaylight: isDaylight,
                severeWeatherRisk: nil
            )

            var baseScore = 80
            let penalty = activitySpecificPenalty(for: activity, hour: dummyHour, hourOfDay: startHour, calendar: calendar)
            baseScore -= penalty

            let score = WeatherScore(rawValue: max(0, baseScore))
            let reason: String
            if score.rawValue < 20 {
                reason = L10n.text("reason_not_suitable")
            } else {
                reason = self.reason(for: activity, score: score, window: window)
            }

            return ActivityRecommendation(
                activityType: activity,
                bestWindow: window,
                score: score,
                reason: reason
            )
        }

        return recommendations.sorted { $0.score.rawValue > $1.score.rawValue }
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

    // MARK: - Activity-Specific Scoring

    private func activitySpecificPenalty(
        for activity: ActivityType,
        hour: HourlyWeatherPoint,
        hourOfDay: Int,
        calendar: Calendar
    ) -> Int {
        let temp = hour.apparentTemperatureCelsius
        let wind = hour.windSpeedKph ?? 0
        let precip = hour.precipitationChance ?? 0
        let uv = hour.uvIndex ?? 0
        let isDaylight = hour.isDaylight ?? false
        let month = calendar.component(.month, from: hour.date)

        switch activity {
        case .goingOutside:
            return 0

        case .swimming:
            guard temp >= 25 else { return 100 }
            var penalty = 0
            if precip >= 0.20 { penalty += 25 }
            if wind >= 15 { penalty += 20 }
            if uv >= 8 { penalty += 15 }
            return penalty

        case .cycling:
            var penalty = 0
            if temp < 10 || temp > 35 { penalty += 50 }
            if precip >= 0.40 { penalty += 30 }
            if wind >= 30 { penalty += 25 }
            else if wind >= 20 { penalty += 10 }
            return penalty

        case .running:
            var penalty = 0
            if temp < 5 || temp > 30 { penalty += 35 }
            if wind >= 30 { penalty += 20 }
            else if wind >= 20 { penalty += 10 }
            if uv >= 8 { penalty += 15 }
            else if uv >= 6 { penalty += 5 }
            return penalty

        case .hiking:
            var penalty = 0
            if temp < 5 || temp > 35 { penalty += 40 }
            if uv >= 7 { penalty += 20 }
            if precip >= 0.50 { penalty += 25 }
            if (6...10).contains(hourOfDay) && isDaylight {
                penalty -= 10
            }
            return penalty

        case .photography:
            var penalty = 0
            if isGoldenHourPeriod(hourOfDay: hourOfDay, month: month) {
                penalty -= 20
            }
            if wind >= 15 { penalty += 20 }
            if precip >= 0.30 { penalty += 30 }
            if precip < 0.10 && !isGoldenHourPeriod(hourOfDay: hourOfDay, month: month) {
                penalty -= 5
            }
            return penalty

        case .picnic:
            var penalty = 0
            if temp < 20 || temp > 30 { penalty += 40 }
            if precip >= 0.30 { penalty += 35 }
            if uv >= 6 { penalty += 20 }
            if !isDaylight { penalty += 50 }
            return penalty

        case .beach:
            var penalty = 0
            if temp < 25 { penalty += 60 }
            if precip >= 0.20 { penalty += 30 }
            return penalty

        case .outdoorDining:
            var penalty = 0
            if temp < 15 || temp > 30 { penalty += 35 }
            if precip >= 0.40 { penalty += 30 }
            if (18...21).contains(hourOfDay) && isDaylight {
                penalty -= 10
            }
            return penalty

        case .sightseeing:
            var penalty = 0
            if temp < 10 || temp > 35 { penalty += 35 }
            if precip >= 0.50 { penalty += 25 }
            if !isDaylight { penalty += 30 }
            return penalty

        case .gardening:
            var penalty = 0
            if temp < 10 || temp > 30 { penalty += 35 }
            if let severe = hour.severeWeatherRisk, severe == .extreme || severe == .high {
                penalty += 80
            }
            if precip >= 0.60 { penalty += 15 }
            return penalty

        case .walking:
            var penalty = 0
            if temp < 0 || temp > 35 { penalty += 35 }
            if let severe = hour.severeWeatherRisk, severe == .extreme {
                penalty += 60
            }
            if wind >= 40 { penalty += 25 }
            else if wind >= 30 { penalty += 10 }
            return penalty
        }
    }

    private func isGoldenHourPeriod(hourOfDay: Int, month: Int) -> Bool {
        let isSummer = (5...8).contains(month)
        let isWinter = month <= 2 || month >= 11

        let morning: Range<Int>
        let evening: Range<Int>

        if isSummer {
            morning = 5..<8
            evening = 18..<21
        } else if isWinter {
            morning = 7..<9
            evening = 16..<18
        } else {
            morning = 6..<8
            evening = 17..<19
        }

        return morning.contains(hourOfDay) || evening.contains(hourOfDay)
    }

    // MARK: - Helpers

    private func seasonalScore(for activity: ActivityType, start: Date, end: Date) -> WeatherScore {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: start)

        switch activity {
        case .swimming:
            if month <= 3 || month >= 11 {
                return WeatherScore(rawValue: 0)
            }
            if month <= 5 || month >= 9 {
                return WeatherScore(rawValue: 30)
            }
            return WeatherScore(rawValue: 60)
        case .picnic, .beach:
            if month <= 3 || month >= 11 {
                return WeatherScore(rawValue: 10)
            }
            if month <= 4 || month >= 10 {
                return WeatherScore(rawValue: 35)
            }
            return WeatherScore(rawValue: 65)
        case .photography:
            return WeatherScore(rawValue: 55)
        case .cycling, .running, .hiking, .walking:
            return WeatherScore(rawValue: 55)
        case .outdoorDining, .sightseeing, .gardening:
            return WeatherScore(rawValue: 55)
        case .goingOutside:
            return WeatherScore(rawValue: 55)
        }
    }

    private func uvEstimate(for hourOfDay: Int, month: Int) -> Int {
        guard (9...17).contains(hourOfDay) else { return 1 }
        let isSummer = (5...8).contains(month)
        if isSummer {
            switch hourOfDay {
            case 11...14: return 8
            case 10, 15: return 6
            default: return 4
            }
        } else {
            switch hourOfDay {
            case 11...14: return 4
            default: return 2
            }
        }
    }

    /// Küresel ısınma odaklı ısı cezası - yüksek sıcaklıklar artık çok daha ağır cezalandırılıyor.
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

    /// Nem cezası - ısı + nem kombinasyonu (Heat Index / Humidex) çok daha agresif.
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
        if activity == .goingOutside {
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

        let time = window.shortDisplayText
        switch score.rawValue {
        case 80...:
            return String(format: L10n.text("reason_best_time"), activity.localizedTitle, time)
        case 60..<80:
            return String(format: L10n.text("reason_good_time"), activity.localizedTitle, time)
        case 20..<60:
            return String(format: L10n.text("reason_moderate_time"), activity.localizedTitle, time)
        default:
            return String(format: L10n.text("reason_not_suitable"), activity.localizedTitle)
        }
    }
}
