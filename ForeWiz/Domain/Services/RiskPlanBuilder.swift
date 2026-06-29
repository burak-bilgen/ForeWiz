import Foundation

enum RiskPlanBuilder {

    static func makeAlertPlans(
        recommendation: DailyRecommendation,
        now: Date,
        calendar: Calendar
    ) -> [NotificationPlan] {
        let highRisks = recommendation.risks.filter { $0.severity >= .high }
        guard !highRisks.isEmpty else { return [] }

        return highRisks.compactMap { risk -> NotificationPlan? in
            let fireDate = calendar.date(byAdding: .minute, value: 5, to: now) ?? now.addingTimeInterval(5 * 60)

            return NotificationPlan(
                id: "alert.\(risk.type.rawValue).\(stableDateID(date: now, calendar: calendar))",
                category: .weatherAlert,
                fireDate: fireDate,
                title: risk.title,
                body: risk.message,
                priority: risk.severity == .extreme ? 100 : 90,
                reason: risk.message
            )
        }
    }

    private static func stableDateID(date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
}
