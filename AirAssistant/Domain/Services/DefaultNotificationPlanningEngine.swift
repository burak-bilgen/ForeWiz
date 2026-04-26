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
           let morningPlan = makeMorningBriefing(
            recommendation: recommendation,
            profile: profile,
            now: now,
            calendar: calendar
           ) {
            candidates.append(morningPlan)
        }

        if enabledCategories.contains(.bestRunWindow),
           let runningWindow = recommendation.bestActivityWindows.first(where: { $0.activityType == .running }),
           let plan = makeActivityPlan(activityRecommendation: runningWindow, now: now, calendar: calendar) {
            candidates.append(plan)
        }

        candidates.append(
            contentsOf: makeRiskPlans(
                recommendation: recommendation,
                enabledCategories: enabledCategories,
                now: now,
                calendar: calendar
            )
        )

        let uniqueCandidates = deduplicate(candidates)
            .filter { $0.fireDate >= now }
            .filter { isQuiet($0.fireDate, quietHours: profile.quietHours, calendar: calendar) == false }
            .sorted {
                if $0.priority == $1.priority {
                    return $0.fireDate < $1.fireDate
                }
                return $0.priority > $1.priority
            }

        return Array(uniqueCandidates.prefix(profile.maximumDailyNotifications.clamped(to: 1...3)))
    }

    private func makeMorningBriefing(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let preference = profile.notificationPreferences.first { $0.category == .morningBriefing }
        let preferredTime = preference?.preferredTime ?? DateComponents(hour: 8, minute: 0)
        guard let fireDate = calendar.nextDate(
            after: calendar.startOfDay(for: now).addingTimeInterval(-1),
            matching: preferredTime,
            matchingPolicy: .nextTime
        ) else {
            return nil
        }

        return NotificationPlan(
            id: stableID(category: .morningBriefing, fireDate: fireDate, calendar: calendar),
            category: .morningBriefing,
            fireDate: fireDate,
            title: "Bugünün hava kararı",
            body: recommendation.summaryText,
            priority: 70,
            reason: "Kullanıcının sabah özeti tercihi açık."
        )
    }

    private func makeActivityPlan(
        activityRecommendation: ActivityRecommendation,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        guard let fireDate = calendar.date(
            byAdding: .minute,
            value: -45,
            to: activityRecommendation.bestWindow.start
        ), fireDate >= now else {
            return nil
        }

        return NotificationPlan(
            id: stableID(category: .bestRunWindow, fireDate: fireDate, calendar: calendar),
            category: .bestRunWindow,
            fireDate: fireDate,
            title: "Koşu için iyi pencere",
            body: "Koşu için en iyi saat \(activityRecommendation.bestWindow.shortDisplayText).",
            priority: 95,
            reason: activityRecommendation.reason
        )
    }

    private func makeRiskPlans(
        recommendation: DailyRecommendation,
        enabledCategories: Set<NotificationCategory>,
        now: Date,
        calendar: Calendar
    ) -> [NotificationPlan] {
        recommendation.avoidWindows.compactMap { avoidWindow in
            guard let category = notificationCategory(for: avoidWindow.risk.type),
                  enabledCategories.contains(category),
                  avoidWindow.severity >= .medium,
                  let fireDate = calendar.date(byAdding: .minute, value: -30, to: avoidWindow.window.start),
                  fireDate >= now else {
                return nil
            }

            return NotificationPlan(
                id: stableID(category: category, fireDate: fireDate, calendar: calendar),
                category: category,
                fireDate: fireDate,
                title: title(for: category),
                body: body(for: avoidWindow),
                priority: priority(for: avoidWindow),
                reason: avoidWindow.reason
            )
        }
    }

    private func notificationCategory(for riskType: WeatherRiskType) -> NotificationCategory? {
        switch riskType {
        case .heat:
            .avoidHeatWindow
        case .uv:
            .uvWarning
        case .rain:
            .rainWarning
        case .wind:
            .windWarning
        case .humidity, .cold, .storm, .poorComfort:
            nil
        }
    }

    private func title(for category: NotificationCategory) -> String {
        switch category {
        case .morningBriefing:
            "Bugünün hava kararı"
        case .outfitSuggestion:
            "Kıyafet önerisi"
        case .bestRunWindow:
            "Koşu zamanı"
        case .avoidHeatWindow:
            "Sıcak saat uyarısı"
        case .rainWarning:
            "Yağmur uyarısı"
        case .windWarning:
            "Rüzgar uyarısı"
        case .uvWarning:
            "UV uyarısı"
        }
    }

    private func body(for avoidWindow: AvoidWindowRecommendation) -> String {
        switch avoidWindow.risk.type {
        case .heat:
            "Bugün \(avoidWindow.window.shortDisplayText) arası sıcaklık yüksek. Uzun süre dışarıda kalma."
        case .uv:
            "\(avoidWindow.window.shortDisplayText) arası UV yüksek. Güneş koruması kullan."
        case .rain:
            "\(avoidWindow.window.shortDisplayText) arası yağmur ihtimali yüksek. Şemsiye al."
        case .wind:
            "\(avoidWindow.window.shortDisplayText) arası rüzgar artıyor. Açık alan planlarını dikkatli yap."
        case .humidity, .cold, .storm, .poorComfort:
            avoidWindow.reason
        }
    }

    private func priority(for avoidWindow: AvoidWindowRecommendation) -> Int {
        switch avoidWindow.severity {
        case .extreme:
            100
        case .high:
            92
        case .medium:
            78
        case .low:
            40
        }
    }

    private func deduplicate(_ plans: [NotificationPlan]) -> [NotificationPlan] {
        var seenCategories: Set<NotificationCategory> = []
        var uniquePlans: [NotificationPlan] = []

        for plan in plans.sorted(by: { $0.priority > $1.priority })
            where seenCategories.contains(plan.category) == false {
            seenCategories.insert(plan.category)
            uniquePlans.append(plan)
        }

        return uniquePlans
    }

    private func isQuiet(_ date: Date, quietHours: TimeWindow?, calendar: Calendar) -> Bool {
        guard let quietHours else {
            return false
        }

        return quietHours.containsClockTime(of: date, calendar: calendar)
    }

    private func stableID(category: NotificationCategory, fireDate: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: fireDate)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "smart.\(category.rawValue).\(year)-\(month)-\(day)"
    }
}
