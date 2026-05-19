import Foundation

// MARK: - Outfit Plan Builder

/// Builds the outfit suggestion notification plan from weather recommendation data.
enum OutfitPlanBuilder {

    static func makePlan(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let preference = profile.notificationPreferences.first { $0.category == .outfitSuggestion }
        let preferredTime = preference?.preferredTime ?? DateComponents(hour: 7, minute: 45)

        guard let fireDate = calendar.nextDate(
            after: now,
            matching: preferredTime,
            matchingPolicy: .nextTime
        ) else { return nil }

        let body = buildBody(recommendation.outfit)

        return NotificationPlan(
            id: NotificationPlanHelpers.stableID(category: .outfitSuggestion, fireDate: fireDate, calendar: calendar),
            category: .outfitSuggestion,
            fireDate: fireDate,
            title: L10n.text("what_to_wear_today"),
            body: body,
            priority: 60,
            reason: L10n.text("notification_outfit_reason")
        )
    }

    // MARK: - Body Builder

    private static func buildBody(_ outfit: OutfitRecommendation) -> String {
        let items = outfit.items.prefix(3).joined(separator: ", ")
        let accessories = outfit.accessories.prefix(2).joined(separator: ", ")

        var sentences: [String] = []
        if items.isEmpty {
            sentences.append(outfit.title)
        } else {
            sentences.append(String(format: L10n.text("outfit_items_format"), items))
        }

        if accessories.isEmpty == false {
            sentences.append(String(format: L10n.text("outfit_accessories_format"), accessories))
        }

        if let warning = outfit.warning {
            sentences.append(warning)
        }

        return sentences.joined(separator: " ")
    }
}
