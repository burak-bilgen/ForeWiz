import Foundation

struct DefaultWeatherDecisionEngine: WeatherDecisionEngine {
    private let activityWindowScoringEngine: ActivityWindowScoringEngine
    private let outfitDecisionEngine: OutfitDecisionEngine
    private let riskClassifier: DefaultWeatherRiskClassifier

    init(
        activityWindowScoringEngine: ActivityWindowScoringEngine = DefaultActivityWindowScoringEngine(),
        outfitDecisionEngine: OutfitDecisionEngine = DefaultOutfitDecisionEngine()
    ) {
        self.activityWindowScoringEngine = activityWindowScoringEngine
        self.outfitDecisionEngine = outfitDecisionEngine
        self.riskClassifier = DefaultWeatherRiskClassifier(
            activityWindowScoringEngine: activityWindowScoringEngine
        )
    }

    func makeDailyRecommendation(
        snapshot: WeatherSnapshot,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar = .current
    ) -> DailyRecommendation {
        let todayHours = relevantHours(from: snapshot.hourly, now: now, calendar: calendar)
        let isTomorrow = todayHours.first.map { !calendar.isDate($0.date, inSameDayAs: now) } ?? false
        let forecastRisks = riskClassifier.uniqueRisks(from: todayHours, current: snapshot.current, calendar: calendar)
        let risks = uniqueRisks(forecastRisks + weatherAlertRisks(from: snapshot.alerts)
            + minuteForecastRisks(from: snapshot.minute, now: now))

        let avoidWindows = (
            riskClassifier.makeAvoidWindows(from: todayHours, profile: profile, calendar: calendar)
            + minuteAvoidWindows(from: snapshot.minute, now: now, calendar: calendar)
        ).sorted { $0.window.start < $1.window.start }

        let outdoorScore = makeOutdoorScore(from: todayHours, profile: profile, risks: risks, calendar: calendar)
        let outdoorDecision = OutdoorDecision(score: outdoorScore)

        let bestOutdoorWindow: TimeWindow? = calculateBestWindow(
            from: snapshot.hourly,
            profile: profile,
            now: now,
            outdoorDecision: outdoorDecision,
            risks: risks,
            avoidWindows: avoidWindows,
            calendar: calendar
        )

        let goingOutRecommendation: ActivityRecommendation? = bestOutdoorWindow.map { window in
            ActivityRecommendation(
                activityType: .goingOutside,
                bestWindow: window,
                score: WeatherScore(rawValue: 80),
                reason: ""
            )
        }

        let outfit = outfitDecisionEngine.recommendOutfit(input: OutfitRecommendationInput(
            current: snapshot.current,
            hourly: todayHours,
            profile: profile,
            risks: risks,
            avoidWindows: avoidWindows,
            calendar: calendar
        ))

        return DailyRecommendation(
            generatedAt: now,
            outdoorDecision: outdoorDecision,
            outdoorScore: outdoorScore,
            bestOutdoorWindow: bestOutdoorWindow,
            bestActivityWindows: goingOutRecommendation.map { [$0] } ?? [],
            avoidWindows: avoidWindows,
            outfit: outfit,
            risks: risks,
            summaryText: summaryText(decision: outdoorDecision, bestWindow: bestOutdoorWindow, risks: risks),
            explanation: explanation(score: outdoorScore, risks: risks, avoidWindows: avoidWindows),
            isTomorrowsRecommendation: isTomorrow
        )
    }

    private func calculateBestWindow(
        from hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        now: Date,
        outdoorDecision: OutdoorDecision,
        risks: [WeatherRisk],
        avoidWindows: [AvoidWindowRecommendation],
        calendar: Calendar
    ) -> TimeWindow? {
        guard outdoorDecision != .avoid else { return nil }
        guard risks.contains(where: { $0.severity == .extreme }) == false else { return nil }

        let dayHours = hourly
            .filter { calendar.isDate($0.date, inSameDayAs: now) }
            .filter { hour in
                let h = calendar.component(.hour, from: hour.date)
                return (7...21).contains(h)
            }
            .sorted { $0.date < $1.date }

        guard !dayHours.isEmpty else { return nil }

        let baseDate = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now

        guard let recommendation = activityWindowScoringEngine.bestWindow(
            for: .goingOutside,
            hourly: dayHours,
            profile: profile,
            now: baseDate,
            calendar: calendar,
            avoidWindows: avoidWindows
        ) else { return nil }

        guard recommendation.bestWindow.end >= now else { return nil }

        return recommendation.bestWindow
    }

    private func relevantHours(
        from hourly: [HourlyWeatherPoint],
        now: Date,
        calendar: Calendar
    ) -> [HourlyWeatherPoint] {
        let today = hourly.filter { calendar.isDate($0.date, inSameDayAs: now) && $0.date >= now }
        if today.isEmpty == false {
            return Array(today.sorted { $0.date < $1.date }.prefix(24))
        }
        return Array(hourly.filter { $0.date >= now }.sorted { $0.date < $1.date }.prefix(24))
    }

    private func uniqueRisks(_ risks: [WeatherRisk]) -> [WeatherRisk] {
        var bestByType: [WeatherRiskType: WeatherRisk] = [:]
        for risk in risks {
            if let existing = bestByType[risk.type], risk.severity <= existing.severity {
                continue
            }
            bestByType[risk.type] = risk
        }
        return bestByType.values.sorted {
            if $0.severity == $1.severity {
                return $0.type.rawValue < $1.type.rawValue
            }
            return $0.severity > $1.severity
        }
    }

    private func weatherAlertRisks(from alerts: [WeatherAlertInfo]?) -> [WeatherRisk] {
        (alerts ?? []).map { alert in
            WeatherRisk(
                type: riskType(for: alert.summary),
                severity: alert.severity,
                title: alert.summary,
                message: alert.region.map { "\($0) - \(alert.source)" } ?? alert.source
            )
        }
    }

    private func minuteForecastRisks(from minute: [MinuteWeatherPoint]?, now: Date) -> [WeatherRisk] {
        guard let peak = peakMinuteRain(from: minute, now: now) else { return [] }

        let severity: RiskLevel
        if peak.precipitationChance >= 0.75 || peak.precipitationIntensityMmPerHour >= 2 {
            severity = .high
        } else if peak.precipitationChance >= 0.45 || peak.precipitationIntensityMmPerHour >= 0.3 {
            severity = .medium
        } else {
            severity = .low
        }

        guard severity >= .medium else { return [] }

        let minutes = max(1, Int(peak.date.timeIntervalSince(now) / 60))
        let chance = Int((peak.precipitationChance * 100).rounded())
        return [
            WeatherRisk(
                type: .rain,
                severity: severity,
                title: L10n.text("risk_nearby_rain"),
                message: String(format: L10n.text("risk_nearby_rain_message"), chance, minutes)
            )
        ]
    }

    private func minuteAvoidWindows(
        from minute: [MinuteWeatherPoint]?,
        now: Date,
        calendar: Calendar
    ) -> [AvoidWindowRecommendation] {
        guard let risk = minuteForecastRisks(from: minute, now: now).first,
              risk.severity >= .medium else { return [] }

        let end = calendar.date(byAdding: .minute, value: 90, to: now) ?? now.addingTimeInterval(90 * 60)
        let window = TimeWindow(start: now, end: end)
        return [
            AvoidWindowRecommendation(
                window: window,
                risk: risk,
                reason: risk.message,
                severity: risk.severity
            )
        ]
    }

    private func peakMinuteRain(from minute: [MinuteWeatherPoint]?, now: Date) -> MinuteWeatherPoint? {
        let nextHour = now.addingTimeInterval(60 * 60)
        return minute?
            .filter { $0.date >= now && $0.date <= nextHour }
            .filter { $0.precipitationType.lowercased() != "none" || $0.precipitationChance >= 0.2 }
            .max {
                let lhs = ($0.precipitationChance * 100) + ($0.precipitationIntensityMmPerHour * 12)
                let rhs = ($1.precipitationChance * 100) + ($1.precipitationIntensityMmPerHour * 12)
                return lhs < rhs
            }
    }

    private func riskType(for alertSummary: String) -> WeatherRiskType {
        let summary = alertSummary.lowercased()
        if summary.contains("rain") || summary.contains("flood") || summary.contains("yağ") || summary.contains("sel") {
            return .rain
        }
        if summary.contains("wind") || summary.contains("rüzgar") || summary.contains("rüzgâr") {
            return .wind
        }
        if summary.contains("heat") || summary.contains("sıcak") {
            return .heat
        }
        if summary.contains("snow") || summary.contains("ice") || summary.contains("kar") || summary.contains("buz") {
            return .cold
        }
        if summary.contains("uv") || summary.contains("sun") || summary.contains("güneş") {
            return .uv
        }
        return .storm
    }

    private func makeOutdoorScore(
        from hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        risks: [WeatherRisk],
        calendar: Calendar
    ) -> WeatherScore {
        let activeScores = hourly
            .filter { hour in
                let h = calendar.component(.hour, from: hour.date)
                return isActiveHour(h, profile: profile)
            }
            .map {
                activityWindowScoringEngine.score(
                    hour: $0,
                    activity: .goingOutside,
                    profile: profile,
                    calendar: calendar
                ).rawValue
            }

        guard activeScores.isEmpty == false else {
            return WeatherScore(rawValue: 40, label: L10n.text("weather_limited_data"))
        }

        let average = Double(activeScores.reduce(0, +)) / Double(activeScores.count)
        var score = Int(average.rounded())

        if risks.contains(where: { $0.severity == .extreme }) {
            score = min(score, 34)
        } else if risks.contains(where: { $0.severity == .high }) {
            score = min(score, 58)
        } else if risks.contains(where: { $0.severity == .medium }) {
            score = min(score, 74)
        }

        return WeatherScore(rawValue: score)
    }

    private func isActiveHour(_ hourOfDay: Int, profile: UserComfortProfile) -> Bool {
        let startHour = 7

        let endHour = profile.quietHours.map { Calendar.current.component(.hour, from: $0.start) } ?? 21

        if endHour > startHour {
            return hourOfDay >= startHour && hourOfDay < endHour
        } else {
            return hourOfDay >= startHour || hourOfDay < endHour
        }
    }

    private func summaryText(
        decision: OutdoorDecision,
        bestWindow: TimeWindow?,
        risks: [WeatherRisk]
    ) -> String {
        if let risk = risks.first(where: { $0.severity >= .high }) {
            return String(format: L10n.text("summary_risk_format"), risk.title, L10n.text("decision_risk_high_message"))
        }

        if let bestWindow {
            return String(format: L10n.text("summary_best_time_format"), bestWindow.shortDisplayText, L10n.text("decision_best_window_message"))
        }

        switch decision {
        case .good: return L10n.text("decision_good_message")
        case .moderate: return L10n.text("decision_moderate_message")
        case .risky: return L10n.text("decision_risky_message")
        case .avoid: return L10n.text("decision_avoid_message")
        }
    }

    private func explanation(
        score: WeatherScore,
        risks: [WeatherRisk],
        avoidWindows: [AvoidWindowRecommendation]
    ) -> String {
        let riskText = risks.isEmpty
            ? L10n.text("decision_no_risk")
            : risks.map { $0.title.lowercased() }.joined(separator: ", ")
        let avoidText = avoidWindows.isEmpty
            ? L10n.text("decision_no_avoid")
            : avoidWindows.map(\.window.shortDisplayText).joined(separator: ", ")

        return String(format: L10n.text("explanation_format"), String(score.displayValue), riskText, avoidText)
    }
}
