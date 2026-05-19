import Foundation

// MARK: - Risk Plan Builder

/// Builds smart (scheduled) and immediate (urgent) risk notification plans from weather recommendation data.
enum RiskPlanBuilder {

    static func makeSmartPlans(
        recommendation: DailyRecommendation,
        enabledCategories: Set<NotificationCategory>,
        now: Date,
        calendar: Calendar
    ) -> [NotificationPlan] {
        let eligible = recommendation.avoidWindows.filter { window in
            guard let category = NotificationPlanHelpers.notificationCategory(for: window.risk.type),
                  enabledCategories.contains(category),
                  window.severity >= .medium,
                  window.window.start >= now else {
                return false
            }
            return true
        }

        let grouped = Dictionary(grouping: eligible) { window in
            NotificationPlanHelpers.fireDate(for: window, now: now, calendar: calendar)
        }

        return grouped.compactMap { startDate, windows in
            makeCombinedPlan(windows: windows, fireDate: startDate, calendar: calendar)
        }
        .sorted { p0, p1 in
            if p0.fireDate == p1.fireDate {
                return p0.category.rawValue < p1.category.rawValue
            }
            return p0.fireDate < p1.fireDate
        }
    }

    static func makeImmediatePlans(
        recommendation: DailyRecommendation,
        enabledCategories: Set<NotificationCategory>,
        now: Date,
        calendar: Calendar
    ) -> [NotificationPlan] {
        let fireDate = calendar.date(byAdding: .minute, value: 5, to: now) ?? now.addingTimeInterval(5 * 60)

        return recommendation.risks
            .filter { $0.severity >= .high }
            .compactMap { risk -> NotificationPlan? in
                guard let category = NotificationPlanHelpers.notificationCategory(for: risk.type),
                      enabledCategories.contains(category) else { return nil }

                return NotificationPlan(
                    id: NotificationPlanHelpers.stableID(category: category, fireDate: fireDate, calendar: calendar) + ".urgent.\(risk.type.rawValue)",
                    category: category,
                    fireDate: fireDate,
                    title: String(format: L10n.text("immediate_risk_title_format"), risk.title),
                    body: String(format: L10n.text("immediate_risk_body_format"), risk.message, NotificationPlanHelpers.actionText(for: risk)),
                    priority: NotificationPlanHelpers.priorityForSeverity(risk.severity),
                    reason: risk.message
                )
            }
    }

    // MARK: - Combined Risk Plan

    private static func makeCombinedPlan(
        windows: [AvoidWindowRecommendation],
        fireDate: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        guard windows.isEmpty == false else { return nil }
        let sorted = windows.sorted { $0.severity.rawValue > $1.severity.rawValue }

        let severity = sorted[0].severity
        guard severity >= .medium else { return nil }

        let title = sorted[0].risk.title
        let body = buildSmartBody(sorted)

        return NotificationPlan(
            id: smartRiskID(sorted: sorted, fireDate: fireDate, calendar: calendar),
            category: NotificationPlanHelpers.notificationCategory(for: sorted[0].risk.type) ?? .avoidHeatWindow,
            fireDate: fireDate,
            title: title,
            body: body,
            priority: NotificationPlanHelpers.priorityForSeverity(severity),
            reason: sorted.map(\.reason).joined(separator: "; ")
        )
    }

    private static func buildSmartBody(_ windows: [AvoidWindowRecommendation]) -> String {
        let time = windows[0].window.shortDisplayText
        let risks = windows.prefix(2).map { $0.risk.title }.joined(separator: ", ")
        let primary = windows[0].risk

        return String(format: L10n.text("smart_risk_body_format"), time, risks, NotificationPlanHelpers.actionText(for: primary))
    }

    private static func smartRiskID(sorted: [AvoidWindowRecommendation], fireDate: Date, calendar: Calendar) -> String {
        let types = sorted.map { $0.risk.type.rawValue }.sorted().joined(separator: "+")
        let components = calendar.dateComponents([.year, .month, .day], from: fireDate)
        let date = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        return "forewiz.risk.\(types).\(date)"
    }
}
