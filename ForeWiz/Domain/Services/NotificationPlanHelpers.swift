import Foundation

// MARK: - Notification Plan Helpers

/// Shared utility functions used by notification plan builders.
enum NotificationPlanHelpers {

    /// Whether a plan is worth notifying at its scheduled time.
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

    /// Whether the fire date falls within quiet hours.
    static func isQuiet(_ date: Date, quietHours: TimeWindow?, calendar: Calendar) -> Bool {
        guard let quietHours else { return false }
        return quietHours.containsClockTime(of: date, calendar: calendar)
    }

    /// Removes duplicate notification plans by category + title prefix.
    static func deduplicateSmart(_ plans: [NotificationPlan]) -> [NotificationPlan] {
        var seen = Set<String>()
        return plans.filter { plan in
            let key = "\(plan.category)-\(plan.title.prefix(10))"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    /// Stable daily ID for a notification category.
    static func stableID(category: NotificationCategory, fireDate: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: fireDate)
        let date = "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        return "forewiz.\(category.rawValue).\(date)"
    }
}
