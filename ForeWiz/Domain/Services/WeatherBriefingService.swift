import Foundation

/// The master service that orchestrates all weather analysis.
/// Combines narrative storytelling, health intelligence, and comparative analysis
/// into a single comprehensive daily briefing.
struct WeatherBriefingService {
    private let narrativeService = WeatherNarrativeService()
    private let healthService = HealthWeatherService()
    private let comparativeService = ComparativeWeatherService()

    /// Generates a complete daily briefing from weather data.
    /// Call this once per recommendation cycle to populate the briefing.
    func generateBriefing(
        snapshot: WeatherSnapshot,
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        calendar: Calendar = .current
    ) -> DailyWeatherBriefing {
        let narrative = narrativeService.generateNarrative(
            snapshot: snapshot,
            recommendation: recommendation,
            calendar: calendar
        )

        let health = healthService.analyzeHealth(
            snapshot: snapshot,
            recommendation: recommendation,
            profile: profile,
            calendar: calendar
        )

        let comparative = comparativeService.analyze(
            snapshot: snapshot,
            recommendation: recommendation,
            calendar: calendar
        )

        let keyTakeaway = generateKeyTakeaway(
            narrative: narrative,
            health: health,
            comparative: comparative,
            recommendation: recommendation
        )

        let actionItems = generateActionItems(
            narrative: narrative,
            health: health,
            comparative: comparative,
            recommendation: recommendation,
            snapshot: snapshot
        )

        return DailyWeatherBriefing(
            narrative: narrative,
            health: health,
            comparative: comparative,
            keyTakeaway: keyTakeaway,
            actionItems: actionItems,
            generatedAt: Date()
        )
    }

    // MARK: - Key Takeaway

    private func generateKeyTakeaway(
        narrative: WeatherNarrative,
        health: HealthWeatherAnalysis,
        comparative: ComparativeWeatherAnalysis,
        recommendation: DailyRecommendation
    ) -> String {
        // If there's a critical risk, highlight that
        if let criticalRisk = recommendation.risks.first(where: { $0.severity == .extreme }) {
            return String(format: L10n.text("briefing_takeaway_critical"), criticalRisk.title)
        }

        // If health score is very low, highlight health
        if health.overallHealthScore < 40 {
            return L10n.text("briefing_takeaway_health")
        }

        // If unusually hot/cold
        if comparative.temperatureAnomalyCelsius.map({ abs($0) >= 4 }) ?? false {
            return String(format: L10n.text("briefing_takeaway_anomaly"), comparative.anomalyLabel)
        }

        // Default: reference best window
        if let window = recommendation.bestOutdoorWindow {
            return String(format: L10n.text("briefing_takeaway_window"), window.shortDisplayText)
        }

        return narrative.headline
    }

    // MARK: - Action Items

    private func generateActionItems(
        narrative: WeatherNarrative,
        health: HealthWeatherAnalysis,
        comparative: ComparativeWeatherAnalysis,
        recommendation: DailyRecommendation,
        snapshot: WeatherSnapshot
    ) -> [WeatherActionItem] {
        var items: [WeatherActionItem] = []

        // 1. Timing action (best window)
        if let window = recommendation.bestOutdoorWindow {
            items.append(WeatherActionItem(
                id: "timing-best-window",
                priority: 1,
                icon: "clock.fill",
                title: L10n.text("action_best_time"),
                description: String(format: L10n.text("action_best_time_desc"), window.shortDisplayText),
                category: .timing
            ))
        }

        // 2. Avoid windows
        if let avoid = recommendation.avoidWindows.first {
            items.append(WeatherActionItem(
                id: "avoid-\(avoid.id)",
                priority: 2,
                icon: "exclamationmark.triangle.fill",
                title: L10n.text("action_avoid"),
                description: String(format: L10n.text("action_avoid_desc"), avoid.window.shortDisplayText, avoid.reason),
                category: .safety
            ))
        }

        // 3. Air Quality action
        if health.airQualityIndex >= 4 {
            items.append(WeatherActionItem(
                id: "health-aqi",
                priority: 3,
                icon: "lungs.fill",
                title: health.airQualityLabel,
                description: health.airQualityAdvice,
                category: .health
            ))
        }

        // 3. Health actions
        if health.migraineRisk >= 6 {
            items.append(WeatherActionItem(
                id: "health-migraine",
                priority: 4,
                icon: "brain.head.profile",
                title: L10n.text("action_migraine"),
                description: health.migraineAdvice,
                category: .health
            ))
        }

        if health.staminaIndex <= 4 {
            items.append(WeatherActionItem(
                id: "health-stamina",
                priority: 5,
                icon: "bolt.slash.fill",
                title: L10n.text("action_stamina"),
                description: health.staminaAdvice,
                category: .health
            ))
        }

        if health.sleepQuality <= 4 {
            items.append(WeatherActionItem(
                id: "health-sleep",
                priority: 5,
                icon: "moon.zzz.fill",
                title: L10n.text("action_sleep"),
                description: health.sleepAdvice,
                category: .health
            ))
        }

        // 4. Outfit action
        if !recommendation.outfit.items.isEmpty {
            items.append(WeatherActionItem(
                id: "outfit-main",
                priority: 6,
                icon: "tshirt.fill",
                title: L10n.text("action_outfit"),
                description: recommendation.outfit.title,
                category: .outfit
            ))
        }

        // 5. Lifestyle tip from narrative
        items.append(WeatherActionItem(
            id: "lifestyle-tip",
            priority: 7,
            icon: "sparkles",
            title: L10n.text("action_pro_tip"),
            description: narrative.proTip,
            category: .lifestyle
        ))

        return items.sorted { $0.priority < $1.priority }
    }
}
