import Foundation

enum MorningBriefingPlanner {

    static func makePlan(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar,
        commuteService: CommuteRouteService? = nil
    ) async -> NotificationPlan? {
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

        if fireDate <= now {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: fireDate) else {
                return nil
            }
            fireDate = nextDay
        }

        let commuteBriefing = await buildCommuteBriefing(profile: profile, commuteService: commuteService)
        let body = buildBody(
            recommendation: recommendation,
            now: now,
            calendar: calendar,
            commuteBriefing: commuteBriefing
        )

        return NotificationPlan(
            id: NotificationPlanHelpers.stableID(category: .morningBriefing, fireDate: fireDate, calendar: calendar),
            category: .morningBriefing,
            fireDate: fireDate,
            title: L10n.text("notification_morning_title"),
            body: body,
            priority: 70,
            reason: "morning_weather_summary"
        )
    }

    private static func buildCommuteBriefing(
        profile: UserComfortProfile,
        commuteService: CommuteRouteService?
    ) async -> CommuteBriefing? {
        guard let commuteService = commuteService else { return nil }
        guard let home = profile.homeLocation, let work = profile.workLocation else { return nil }

        return await commuteService.commuteBriefing(
            home: home,
            work: work,
            mode: TravelMode(rawValue: home.commuteModeRaw) ?? .car
        )
    }

    private static func buildCommuteSection(_ briefing: CommuteBriefing) -> String {
        guard briefing.weatherAtOrigin != "N/A" else {
            return L10n.text("notif_morning_commute_same")
        }

        var lines: [String] = []

        lines.append(L10n.text("notif_morning_commute"))

        if briefing.routeHazards.isEmpty {
            lines.append(String(
                format: L10n.text("notif_morning_commute_body"),
                briefing.summary
            ))
        } else {
            let hazardsStr = briefing.routeHazards.joined(separator: "; ")
            lines.append(String(
                format: L10n.text("notif_morning_commute_hazards"),
                hazardsStr
            ))
        }

        lines.append(String(
            format: L10n.text("notif_morning_commute_origin"),
            briefing.weatherAtOrigin
        ))
        lines.append(String(
            format: L10n.text("notif_morning_commute_dest"),
            briefing.weatherAtDestination
        ))
        lines.append(String(
            format: L10n.text("notif_morning_commute_rec"),
            briefing.recommendation
        ))

        return lines.joined(separator: "\n")
    }

    private static func buildBody(
        recommendation: DailyRecommendation,
        now: Date,
        calendar: Calendar,
        commuteBriefing: CommuteBriefing?
    ) -> String {
        var parts: [String] = []

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

        if let window = recommendation.bestOutdoorWindow, window.end > now {
            let timeInfo = window.shortDisplayText
            switch recommendation.outdoorDecision {
            case .good:
                parts.append(String(format: L10n.text("notif_morning_window_good"), timeInfo))
            default:
                parts.append(String(format: L10n.text("notif_morning_window_ok"), timeInfo))
            }
        }

        if let risk = recommendation.risks.first(where: { $0.severity >= .high }) {
            let riskTip = actionTip(for: risk)
            if let window = recommendation.bestOutdoorWindow, window.end > now {
                parts.append(String(format: L10n.text("notif_morning_risk_with_tip"), risk.title, riskTip))
            } else {
                parts.append(String(format: L10n.text("notif_morning_risk_only"), risk.title, riskTip))
            }
        }

        if let briefing = commuteBriefing {
            parts.append(buildCommuteSection(briefing))
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
        case .airQuality: return L10n.text("notif_tip_air_quality")
        }
    }
}
