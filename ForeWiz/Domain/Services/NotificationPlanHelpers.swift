import Foundation

// MARK: - Notification Plan Helpers

/// Shared utility functions used by notification plan builders.
enum NotificationPlanHelpers {

    // MARK: - Risk Helpers

    static func dominantRisk(in recommendation: DailyRecommendation) -> WeatherRisk? {
        recommendation.risks
            .sorted { lhs, rhs in lhs.severity.rawValue > rhs.severity.rawValue }
            .first { $0.severity >= .medium }
    }

    static func actionText(for risk: WeatherRisk) -> String {
        switch risk.type {
        case .heat: return L10n.text("stick_to_shade_water_and")
        case .uv: return L10n.text("use_sunscreen_a_hat_and")
        case .rain: return L10n.text("bring_an_umbrella_or_move")
        case .wind, .storm: return L10n.text("avoid_long_exposed_outdoor_time")
        case .humidity: return L10n.text("slow_the_pace_and_keep")
        case .cold: return L10n.text("dress_in_layers_and_avoid")
        case .poorComfort: return L10n.text("keeping_outdoor_time_short_is")
        }
    }

    // MARK: - Filtering

    static func isWorthNotifying(plan: NotificationPlan, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: plan.fireDate)
        if hour >= 22 || hour < 6 {
            return plan.priority >= 90
        }
        if hour >= 12 && hour < 14 {
            return plan.priority >= 60
        }
        return true
    }

    static func isQuiet(_ date: Date, quietHours: TimeWindow?, calendar: Calendar) -> Bool {
        guard let quietHours else { return false }
        return quietHours.containsClockTime(of: date, calendar: calendar)
    }

    static func deduplicateSmart(_ plans: [NotificationPlan]) -> [NotificationPlan] {
        var seen = Set<String>()
        return plans.filter { plan in
            let key = "\(plan.category)-\(plan.title.prefix(10))"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    // MARK: - Fire Date

    static func fireDate(
        for window: AvoidWindowRecommendation,
        now: Date,
        calendar: Calendar
    ) -> Date {
        let warningLeadMinutes: Int
        switch window.severity {
        case .extreme: warningLeadMinutes = 60
        case .high: warningLeadMinutes = 45
        case .medium: warningLeadMinutes = 30
        case .low: warningLeadMinutes = 15
        }

        let leadDate = calendar.date(
            byAdding: .minute,
            value: -warningLeadMinutes,
            to: window.window.start
        ) ?? window.window.start

        return max(leadDate, now)
    }

    // MARK: - Category Mapping

    static func notificationCategory(for riskType: WeatherRiskType) -> NotificationCategory? {
        switch riskType {
        case .heat: return .avoidHeatWindow
        case .uv: return .uvWarning
        case .rain: return .rainWarning
        case .wind: return .windWarning
        case .storm: return .stormWarning
        case .cold: return .coldWarning
        case .humidity: return .humidityWarning
        case .poorComfort: return .poorComfortWarning
        }
    }

    static func priorityForSeverity(_ severity: RiskLevel) -> Int {
        switch severity {
        case .extreme: return 100
        case .high: return 90
        case .medium: return 75
        case .low: return 50
        }
    }

    // MARK: - ID Generation

    static func stableID(category: NotificationCategory, fireDate: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: fireDate)
        let date = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        return "forewiz.\(category.rawValue).\(date)"
    }
}
