import Foundation

struct DefaultNotificationPlanningEngine: NotificationPlanningEngine {
    func makePlans(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar = .current
    ) -> [NotificationPlan] {
        let enabledCategories = Set(
            profile.notificationPreferences
                .filter(\.isEnabled)
                .map(\.category)
        )

        var candidates: [NotificationPlan] = []

        if enabledCategories.contains(.morningBriefing),
           let morningPlan = makeSmartMorningBriefing(
            recommendation: recommendation,
            profile: profile,
            now: now,
            calendar: calendar
           ) {
            candidates.append(morningPlan)
        }

        if enabledCategories.contains(.outfitSuggestion),
           let outfitPlan = makeOutfitPlan(
             recommendation: recommendation,
             profile: profile,
             now: now,
             calendar: calendar
            ) {
            candidates.append(outfitPlan)
        }

        if enabledCategories.contains(.bestRunWindow),
           let runningWindow = recommendation.bestActivityWindows.first(where: { $0.activityType == .running }),
           let plan = makeActivityPlan(activityRecommendation: runningWindow, now: now, calendar: calendar),
           isWorthNotifying(plan: plan, now: now) {
            candidates.append(plan)
        }

        candidates.append(
            contentsOf: makeSmartRiskPlans(
                recommendation: recommendation,
                enabledCategories: enabledCategories,
                now: now,
                calendar: calendar
            )
        )

        let deduplicated = deduplicateSmart(candidates)

        let filtered = deduplicated
            .filter { $0.fireDate >= now }
            .filter { isQuiet($0.fireDate, quietHours: profile.quietHours, calendar: calendar) == false }
            .filter { isWorthNotifying(plan: $0, now: now) }

        let sorted = filtered.sorted { p0, p1 in
            if p0.priority == p1.priority {
                return p0.fireDate < p1.fireDate
            }
            return p0.priority > p1.priority
        }

        return Array(sorted.prefix(profile.maximumDailyNotifications.clamped(to: 1...3)))
    }

    private func makeSmartMorningBriefing(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let preference = profile.notificationPreferences.first { $0.category == .morningBriefing }
        var preferredTime = preference?.preferredTime ?? DateComponents(hour: 7, minute: 30)

        guard let fireDate = calendar.nextDate(
            after: calendar.startOfDay(for: now).addingTimeInterval(-1),
            matching: preferredTime,
            matchingPolicy: .nextTime
        ) else {
            return nil
        }

        let body = buildSmartMorningBody(recommendation: recommendation)

        return NotificationPlan(
            id: stableID(category: .morningBriefing, fireDate: fireDate, calendar: calendar),
            category: .morningBriefing,
            fireDate: fireDate,
            title: "Gunaydin!",
            body: body,
            priority: 70,
            reason: "Sabah ozeti"
        )
    }

    private func buildSmartMorningBody(recommendation: DailyRecommendation) -> String {
        var parts: [String] = []

        switch recommendation.outdoorDecision {
        case .good:
            parts.append("Disari harika!")
        case .moderate:
            parts.append("Idare eder.")
        case .risky:
            parts.append("Dikkatli ol.")
        case .avoid:
            parts.append("Disari sorunlu.")
        }

        if let bestWindow = recommendation.bestOutdoorWindow {
            parts.append("En rahat: \(bestWindow.shortDisplayText)")
        }

        let critical = recommendation.risks.first { $0.severity >= .high }
        if let risk = critical {
            parts.append("Dikkat: \(risk.title)")
        }

        return parts.joined(separator: " - ")
    }

    private func makeOutfitPlan(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let preference = profile.notificationPreferences.first { $0.category == .outfitSuggestion }
        var preferredTime = preference?.preferredTime ?? DateComponents(hour: 7, minute: 45)

        guard let fireDate = calendar.nextDate(
            after: calendar.startOfDay(for: now).addingTimeInterval(-1),
            matching: preferredTime,
            matchingPolicy: .nextTime
        ) else {
            return nil
        }

        let outfit = recommendation.outfit
        var body = outfit.items.joined(separator: ", ")
        if let warning = outfit.warning {
            body += " (\(warning))"
        }

        return NotificationPlan(
            id: stableID(category: .outfitSuggestion, fireDate: fireDate, calendar: calendar),
            category: .outfitSuggestion,
            fireDate: fireDate,
            title: "Ne giyeyim?",
            body: body,
            priority: 60,
            reason: "Kiyafet oneri"
        )
    }

    private func makeActivityPlan(
        activityRecommendation: ActivityRecommendation,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let fireDate = activityRecommendation.bestWindow.start
        guard fireDate >= now.addingTimeInterval(30 * 60) else {
            return nil
        }

        let time = activityRecommendation.bestWindow.shortDisplayText
        let body: String

        if activityRecommendation.score.rawValue >= 80 {
            body = "Tam ideal! \(time)"
        } else if activityRecommendation.score.rawValue >= 60 {
            body = "Uygun. \(time)"
        } else {
            body = "En iyi: \(time)"
        }

        return NotificationPlan(
            id: stableID(category: .bestRunWindow, fireDate: fireDate, calendar: calendar),
            category: .bestRunWindow,
            fireDate: fireDate,
            title: "\(activityRecommendation.activityType.localizedTitle) zamani",
            body: body,
            priority: 80,
            reason: activityRecommendation.reason
        )
    }

    private func makeSmartRiskPlans(
        recommendation: DailyRecommendation,
        enabledCategories: Set<NotificationCategory>,
        now: Date,
        calendar: Calendar
    ) -> [NotificationPlan] {
        let eligible = recommendation.avoidWindows.filter { window in
            guard let category = notificationCategory(for: window.risk.type),
                  enabledCategories.contains(category),
                  window.severity >= .medium,
                  window.window.start >= now else {
                return false
            }
            return true
        }

        let grouped = Dictionary(grouping: eligible) { $0.window.start }

        return grouped.compactMap { startDate, windows in
            makeCombinedRiskPlan(windows: windows, fireDate: startDate, calendar: calendar)
        }
    }

    private func makeCombinedRiskPlan(
        windows: [AvoidWindowRecommendation],
        fireDate: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        guard let first = windows.first else { return nil }
        let sorted = windows.sorted { $0.severity.rawValue > $1.severity.rawValue }

        let severity = sorted[0].severity
        guard severity >= .medium else { return nil }

        let title = sorted[0].risk.title
        let body = buildSmartRiskBody(sorted)

        return NotificationPlan(
            id: smartRiskID(sorted: sorted, fireDate: fireDate, calendar: calendar),
            category: notificationCategory(for: sorted[0].risk.type) ?? .avoidHeatWindow,
            fireDate: fireDate,
            title: title,
            body: body,
            priority: priorityForSeverity(severity),
            reason: sorted.map(\.reason).joined(separator: "; ")
        )
    }

    private func buildSmartRiskBody(_ windows: [AvoidWindowRecommendation]) -> String {
        let time = windows[0].window.shortDisplayText
        let risks = windows.map { $0.risk.title }.joined(separator: ", ")
        return "\(time): \(risks)"
    }

    private func isWorthNotifying(plan: NotificationPlan, now: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        if hour >= 22 || hour < 6 {
            return plan.priority >= 90
        }
        return true
    }

    private func deduplicateSmart(_ plans: [NotificationPlan]) -> [NotificationPlan] {
        var seen = Set<String>()
        return plans.filter { plan in
            let key = "\(plan.category)-\(plan.title.prefix(10))"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    private func notificationCategory(for riskType: WeatherRiskType) -> NotificationCategory? {
        switch riskType {
        case .heat: return .avoidHeatWindow
        case .uv: return .uvWarning
        case .rain: return .rainWarning
        case .wind: return .windWarning
        case .humidity, .cold, .storm, .poorComfort: return nil
        }
    }

    private func priorityForSeverity(_ severity: RiskLevel) -> Int {
        switch severity {
        case .extreme: return 100
        case .high: return 90
        case .medium: return 75
        case .low: return 50
        }
    }

    private func isQuiet(_ date: Date, quietHours: TimeWindow?, calendar: Calendar) -> Bool {
        guard let quietHours else { return false }
        return quietHours.containsClockTime(of: date, calendar: calendar)
    }

    private func stableID(category: NotificationCategory, fireDate: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: fireDate)
        let date = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        return "weathra.\(category.rawValue).\(date)"
    }

    private func smartRiskID(sorted: [AvoidWindowRecommendation], fireDate: Date, calendar: Calendar) -> String {
        let types = sorted.map { $0.risk.type.rawValue }.sorted().joined(separator: "+")
        let components = calendar.dateComponents([.year, .month, .day], from: fireDate)
        let date = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        return "weathra.risk.\(types).\(date)"
    }
}