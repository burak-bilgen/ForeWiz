import Foundation

enum NotificationPlanHelpers {

    static func isWorthNotifying(plan: NotificationPlan, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: plan.fireDate)

        if hour >= 23 || hour < 7 {
            return plan.priority >= 90
        }

        if hour >= 9 && hour < 12 {
            return plan.priority >= 60
        }
        if hour >= 14 && hour < 17 {
            return plan.priority >= 60
        }

        if hour >= 12 && hour < 14 {
            return plan.priority >= 50
        }

        return true
    }

    static func isQuiet(_ date: Date, quietHours: TimeWindow?, calendar: Calendar) -> Bool {
        guard let quietHours else { return false }
        return quietHours.containsClockTime(of: date, calendar: calendar)
    }

    static func deduplicateSmart(_ plans: [NotificationPlan]) -> [NotificationPlan] {
        var seenExact = Set<String>()
        var seenApprox = Set<String>()

        return plans.filter { plan in
            let exactKey = "\(plan.category)-\(plan.title)-\(plan.body)"
            if seenExact.contains(exactKey) { return false }
            seenExact.insert(exactKey)

            let approxKey = "\(plan.category)-\(plan.body.prefix(30))"
            if seenApprox.contains(approxKey) { return false }
            seenApprox.insert(approxKey)

            return true
        }
    }

    static func stableID(category: NotificationCategory, fireDate: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: fireDate)
        let date = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        return "forewiz.\(category.rawValue).\(date)"
    }
}
