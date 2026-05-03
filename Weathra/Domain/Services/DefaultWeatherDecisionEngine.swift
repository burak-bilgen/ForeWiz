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
        let risks = riskClassifier.uniqueRisks(from: todayHours, current: snapshot.current, calendar: calendar)
        let avoidWindows = riskClassifier.makeAvoidWindows(from: todayHours, profile: profile, calendar: calendar)
        let outdoorScore = makeOutdoorScore(from: todayHours, profile: profile, risks: risks, calendar: calendar)
        let outdoorDecision = OutdoorDecision(score: outdoorScore)
        let bestOutdoorWindow = activityWindowScoringEngine.bestWindow(
            for: .goingOutside,
            hourly: todayHours,
            profile: profile,
            now: now,
            calendar: calendar
        )?.bestWindow
        let activityWindows = makeActivityWindows(
            hourly: todayHours,
            profile: profile,
            now: now,
            calendar: calendar
        )
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
            bestActivityWindows: activityWindows,
            avoidWindows: avoidWindows,
            outfit: outfit,
            risks: risks,
            summaryText: summaryText(decision: outdoorDecision, bestWindow: bestOutdoorWindow, risks: risks),
            explanation: explanation(score: outdoorScore, risks: risks, avoidWindows: avoidWindows)
        )
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

    private func makeOutdoorScore(
        from hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        risks: [WeatherRisk],
        calendar: Calendar
    ) -> WeatherScore {
        let daylightScores = hourly
            .filter { hour in
                let hourOfDay = calendar.component(.hour, from: hour.date)
                return (6...22).contains(hourOfDay)
            }
            .map {
                activityWindowScoringEngine.score(
                    hour: $0,
                    activity: .goingOutside,
                    profile: profile,
                    calendar: calendar
                ).rawValue
            }

        guard daylightScores.isEmpty == false else {
            return WeatherScore(rawValue: 40, label: "Sınırlı veri")
        }

        var score = daylightScores.reduce(0, +) / daylightScores.count

        if risks.contains(where: { $0.severity == .extreme }) {
            score = min(score, 34)
        } else if risks.contains(where: { $0.severity == .high }) {
            score = min(score, 58)
        }

        return WeatherScore(rawValue: score)
    }

    private func makeActivityWindows(
        hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> [ActivityRecommendation] {
        let preferredActivities = profile.preferredActivities.isEmpty
            ? Set([ActivityType.walking])
            : profile.preferredActivities

        return preferredActivities
            .filter { $0 != .goingOutside }
            .sorted { $0.rawValue < $1.rawValue }
            .compactMap {
                activityWindowScoringEngine.bestWindow(
                    for: $0,
                    hourly: hourly,
                    profile: profile,
                    now: now,
                    calendar: calendar
                )
            }
    }

    private func summaryText(
        decision: OutdoorDecision,
        bestWindow: TimeWindow?,
        risks: [WeatherRisk]
    ) -> String {
        if let risk = risks.first(where: { $0.severity >= .high }) {
            return "\(risk.title). Dış planı kısa tut ve saatini değiştirebileceğin bir alternatif bırak."
        }

        if let bestWindow {
            return "Dışarı için en rahat zaman \(bestWindow.shortDisplayText). Uzun planı bu aralığa almak daha konforlu olur."
        }

        switch decision {
        case .good:
            return "Bugün dış plan için koşullar dengeli. Uzun süre dışarıda kalacaksan hava değişimini yine de kontrol et."
        case .moderate:
            return "Dışarı çıkmak için uygun, ancak bazı saatlerde konfor düşebilir. Planı en rahat aralığa denk getirmek daha iyi olur."
        case .risky:
            return "Bugün hava bazı saatlerde yorucu veya riskli olabilir. Uzun dış planı kısalt, mola ve alternatif saat bırak."
        case .avoid:
            return "Bugün dışarıda uzun kalmak iyi bir fikir değil. Zorunlu planları kısa tut, mümkünse daha güvenli bir saate taşı."
        }
    }

    private func explanation(
        score: WeatherScore,
        risks: [WeatherRisk],
        avoidWindows: [AvoidWindowRecommendation]
    ) -> String {
        let riskText = risks.isEmpty
            ? "belirgin risk yok"
            : risks.map { $0.title.lowercased() }.joined(separator: ", ")
        let avoidText = avoidWindows.isEmpty
            ? "kaçınılacak belirgin saat yok"
            : avoidWindows.map(\.window.shortDisplayText).joined(separator: ", ")

        return "Skor \(score.displayValue)/10. Bu karar; hissedilen sıcaklık, yağış olasılığı, rüzgar, UV, nem ve saatlik değişim birlikte okunarak verildi. " +
            "Öne çıkan risk: \(riskText). Dikkat edilmesi gereken zaman: \(avoidText)."
    }
}
