import Foundation

// MARK: - Morning Briefing Planner

/// Builds the morning briefing notification - a short, human-like daily weather summary.
/// All text is in natural Turkish, as if a friend is giving you the weather lowdown.
enum MorningBriefingPlanner {

    static func makePlan(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let preference = profile.notificationPreferences.first { $0.category == .morningBriefing }
        let preferredTime = preference?.preferredTime ?? DateComponents(hour: 7, minute: 0)

        var matchingComponents = preferredTime
        matchingComponents.calendar = calendar
        matchingComponents.timeZone = calendar.timeZone
        matchingComponents.second = 0
        matchingComponents.nanosecond = 0
        matchingComponents.year = calendar.component(.year, from: now)
        matchingComponents.month = calendar.component(.month, from: now)
        matchingComponents.day = calendar.component(.day, from: now)

        guard var fireDate = matchingComponents.date else { return nil }

        // If the computed date is before or equal to now, move to the next day
        if fireDate <= now {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: fireDate) else {
                return nil
            }
            fireDate = nextDay
        }
        let body = buildBody(recommendation: recommendation, now: now, calendar: calendar)

        return NotificationPlan(
            id: NotificationPlanHelpers.stableID(category: .morningBriefing, fireDate: fireDate, calendar: calendar),
            category: .morningBriefing,
            fireDate: fireDate,
            title: L10n.text("notification_morning_title"),
            body: body,
            priority: 70,
            reason: "günlük hava özeti"
        )
    }

    // MARK: - Body Builder

    private static func buildBody(recommendation: DailyRecommendation, now: Date, calendar: Calendar) -> String {
        var parts: [String] = []

        // Opening based on decision - arkadaşça, doğal bir dille
        switch recommendation.outdoorDecision {
        case .good:
            parts.append(L10n.text("notif_morning_good"))
        case .moderate:
            parts.append(L10n.text("notif_morning_moderate"))
        case .risky:
            parts.append(L10n.text("notif_morning_risky"))
        case .avoid:
            parts.append(L10n.text("notif_morning_avoid"))
        }

        // Best window - varsa ve henüz geçmemişse ekle
        if let window = recommendation.bestOutdoorWindow, window.end > now {
            let timeInfo = window.shortDisplayText
            switch recommendation.outdoorDecision {
            case .good:
                parts.append(String(format: L10n.text("notif_morning_window_good"), timeInfo))
            default:
                parts.append(String(format: L10n.text("notif_morning_window_ok"), timeInfo))
            }
        }

        // Top risk warning - doğal dille uyarı
        if let risk = recommendation.risks.first(where: { $0.severity >= .high }) {
            let riskTip = actionTip(for: risk)
            if let window = recommendation.bestOutdoorWindow, window.end > now {
                parts.append(String(format: L10n.text("notif_morning_risk_with_tip"), risk.title, riskTip))
            } else {
                parts.append(String(format: L10n.text("notif_morning_risk_only"), risk.title, riskTip))
            }
        }

        return parts.joined(separator: " ")
    }

    private static func actionTip(for risk: WeatherRisk) -> String {
        switch risk.type {
        case .heat: return L10n.text("notif_tip_heat")
        case .uv: return L10n.text("notif_tip_uv")
        case .rain: return L10n.text("notif_tip_rain")
        case .wind, .storm: return L10n.text("notif_tip_wind")
        case .cold: return L10n.text("notif_tip_cold")
        case .humidity, .poorComfort: return L10n.text("notif_tip_comfort")
        }
    }
}
