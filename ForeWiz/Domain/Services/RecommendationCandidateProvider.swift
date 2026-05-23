import Foundation

protocol RecommendationCandidateProvider {
    func candidates(
        from snapshot: WeatherSnapshot,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> [RecommendationCandidate]
}

struct DefaultRecommendationCandidateProvider: RecommendationCandidateProvider {
    private let activityWindowScoringEngine: ActivityWindowScoringEngine
    private let riskClassifier: DefaultWeatherRiskClassifier

    init(
        activityWindowScoringEngine: ActivityWindowScoringEngine = DefaultActivityWindowScoringEngine(),
        riskClassifier: DefaultWeatherRiskClassifier? = nil
    ) {
        self.activityWindowScoringEngine = activityWindowScoringEngine
        self.riskClassifier = riskClassifier ?? DefaultWeatherRiskClassifier(
            activityWindowScoringEngine: activityWindowScoringEngine
        )
    }

    func candidates(
        from snapshot: WeatherSnapshot,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> [RecommendationCandidate] {
        let hourly = relevantHours(from: snapshot.hourly, now: now, calendar: calendar)
        let current = snapshot.current
        var candidates: [RecommendationCandidate] = []

        candidates.append(outdoorCandidate(hourly: hourly, profile: profile, now: now, calendar: calendar))

        if let goingOut = goingOutCandidate(hourly: hourly, profile: profile, now: now, calendar: calendar) {
            candidates.append(goingOut)
        }

        candidates.append(avoidCandidate(from: snapshot, hourly: hourly, now: now, calendar: calendar))

        // Use the risk classifier instead of duplicating threshold logic
        let detectedRisks = riskClassifier.uniqueRisks(from: hourly, current: current, calendar: calendar)
        for risk in detectedRisks {
            if let candidate = riskCandidate(from: risk, current: current, fetchedAt: snapshot.fetchedAt) {
                candidates.append(candidate)
            }
        }

        return candidates.sorted { $0.score > $1.score }
    }

    private func outdoorCandidate(
        hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> RecommendationCandidate {
        let scores = hourly.map {
            activityWindowScoringEngine.score(hour: $0, activity: .goingOutside, profile: profile, calendar: calendar)
        }
        let averageScore = scores.isEmpty ? 50 : Double(scores.map(\.rawValue).reduce(0, +)) / Double(scores.count)

        var signals: [RecommendationSignal] = []
        if let currentTemp = hourly.first?.apparentTemperatureCelsius {
            signals.append(RecommendationSignal(
                kind: .temperature,
                value: "\(Int(currentTemp))°C",
                weight: 0.3,
                metadata: ["range": temperatureRangeLabel(currentTemp)]
            ))
        }

        return RecommendationCandidate(
            id: UUID(),
            type: .goingOutSuggestion,
            score: averageScore,
            signals: signals,
            metadata: ["headline": outdoorHeadline(for: averageScore)],
            generatedAt: now
        )
    }

    private func goingOutCandidate(
        hourly: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> RecommendationCandidate? {
        guard let recommendation = activityWindowScoringEngine.bestWindow(
            for: .goingOutside,
            hourly: hourly,
            profile: profile,
            now: now,
            calendar: calendar
        ) else { return nil }

        let score = Double(recommendation.score.rawValue)
        let timeWindow = recommendation.bestWindow.shortDisplayText

        let signals: [RecommendationSignal] = [
            RecommendationSignal(
                kind: .schedule,
                value: timeWindow,
                weight: 0.2,
                metadata: [:]
            ),
            RecommendationSignal(
                kind: .activityMatch,
                value: L10n.text("activity_outside"),
                weight: 0.4,
                metadata: [:]
            )
        ]

        return RecommendationCandidate(
            id: UUID(),
            type: .goingOutSuggestion,
            score: score,
            signals: signals,
            metadata: ["timeWindow": timeWindow, "headline": recommendation.reason],
            generatedAt: now
        )
    }

    private func avoidCandidate(
        from snapshot: WeatherSnapshot,
        hourly: [HourlyWeatherPoint],
        now: Date,
        calendar: Calendar
    ) -> RecommendationCandidate {
        let severeHours = hourly.filter { hour in
            hour.severeWeatherRisk == .extreme || hour.severeWeatherRisk == .high
        }

        if severeHours.isEmpty {
            return RecommendationCandidate(
                id: UUID(),
                type: .goingOutSuggestion,
                score: 0,
                signals: [],
                metadata: ["headline": L10n.text("decision_no_avoid")],
                generatedAt: now
            )
        }

        let firstSevere = severeHours[0]
        let signals = [
            RecommendationSignal(
                kind: .riskAvoidance,
                value: "\(firstSevere.severeWeatherRisk ?? .medium)",
                weight: 0.5,
                metadata: [:]
            )
        ]

        return RecommendationCandidate(
            id: UUID(),
            type: .goingOutSuggestion,
            score: Double(severeHours.count) * 15,
            signals: signals,
            metadata: [
                "headline": L10n.text("decision_avoid_message"),
                "timeWindow": firstSevere.date.formatted(date: .omitted, time: .shortened)
            ],
            generatedAt: now
        )
    }

    /// Creates a recommendation candidate from a single classified WeatherRisk.
    /// Uses the classifier's severity and thresholds instead of duplicating logic.
    private func riskCandidate(
        from risk: WeatherRisk,
        current: CurrentWeatherPoint,
        fetchedAt: Date
    ) -> RecommendationCandidate? {
        let signalKind: SignalKind
        let displayValue: String

        switch risk.type {
        case .heat, .cold:
            signalKind = .temperature
            displayValue = "\(Int(current.apparentTemperatureCelsius))°C"
        case .rain:
            signalKind = .precipitation
            displayValue = current.precipitationChance.map { "\(Int($0 * 100))%" } ?? risk.title
        case .wind:
            signalKind = .wind
            displayValue = current.windSpeedKph.map { "\(Int($0)) km/h" } ?? risk.title
        case .uv:
            signalKind = .uvIndex
            displayValue = current.uvIndex.map { "UV \($0)" } ?? risk.title
        case .humidity, .poorComfort:
            signalKind = .riskAvoidance
            displayValue = risk.message
        case .storm:
            signalKind = .riskAvoidance
            displayValue = risk.title
        case .airQuality:
            signalKind = .riskAvoidance
            displayValue = risk.message
        }

        let score: Double = riskSeverityScore(risk.severity)
        let headline = risk.title

        return RecommendationCandidate(
            id: UUID(),
            type: .riskAlert,
            score: score,
            signals: [
                RecommendationSignal(
                    kind: signalKind,
                    value: displayValue,
                    weight: riskSeverityWeight(risk.severity),
                    metadata: [:]
                )
            ],
            metadata: ["headline": headline],
            generatedAt: fetchedAt
        )
    }

    private func riskSeverityScore(_ severity: RiskLevel) -> Double {
        switch severity {
        case .extreme: return 95
        case .high: return 78
        case .medium: return 55
        case .low: return 30
        }
    }

    private func riskSeverityWeight(_ severity: RiskLevel) -> Double {
        switch severity {
        case .extreme: return 0.7
        case .high: return 0.55
        case .medium: return 0.35
        case .low: return 0.2
        }
    }

    private func relevantHours(from hourly: [HourlyWeatherPoint], now: Date, calendar: Calendar) -> [HourlyWeatherPoint] {
        let today = hourly.filter { calendar.isDate($0.date, inSameDayAs: now) && $0.date >= now }
        if !today.isEmpty {
            return Array(today.sorted { $0.date < $1.date }.prefix(24))
        }
        return Array(hourly.filter { $0.date >= now }.sorted { $0.date < $1.date }.prefix(24))
    }

    private func temperatureRangeLabel(_ temp: Double) -> String {
        switch temp {
        case 30...: return L10n.text("recommendation_optimal_range")
        case 20..<30: return L10n.text("recommendation_good_range")
        case 10..<20: return L10n.text("recommendation_moderate_range")
        default: return L10n.text("recommendation_poor_range")
        }
    }

    private func outdoorHeadline(for score: Double) -> String {
        switch score {
        case 80...: return L10n.text("decision_good_message")
        case 60..<80: return L10n.text("decision_moderate_message")
        case 40..<60: return L10n.text("decision_risky_message")
        default: return L10n.text("decision_avoid_message")
        }
    }
}
