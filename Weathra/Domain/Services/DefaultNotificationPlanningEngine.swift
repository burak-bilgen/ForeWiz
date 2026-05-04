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

        let result = deduplicate(candidates)
            .filter { $0.fireDate >= now }
            .filter { isQuiet($0.fireDate, quietHours: profile.quietHours, calendar: calendar) == false }
            .sorted {
                if $0.priority == $1.priority {
                    return $0.fireDate < $1.fireDate
                }
                return $0.priority > $1.priority
            }

        return Array(result.prefix(profile.maximumDailyNotifications.clamped(to: 1...3)))
    }

    private func makeMorningBriefing(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let preference = profile.notificationPreferences.first { $0.category == .morningBriefing }
        let preferredTime = preference?.preferredTime ?? DateComponents(hour: 7, minute: 0)
        guard let fireDate = calendar.nextDate(
            after: calendar.startOfDay(for: now).addingTimeInterval(-1),
            matching: preferredTime,
            matchingPolicy: .nextTime
        ) else {
            return nil
        }

        let body = buildMorningBody(recommendation: recommendation)

        return NotificationPlan(
            id: stableID(category: .morningBriefing, fireDate: fireDate, calendar: calendar),
            category: .morningBriefing,
            fireDate: fireDate,
            title: "Günaydın! İşte bugünün hava raporu",
            body: body,
            priority: 75,
            reason: "Kullanıcının sabah özeti tercihi açık."
        )
    }

    private func buildMorningBody(recommendation: DailyRecommendation) -> String {
        var parts: [String] = []

        switch recommendation.outdoorDecision {
        case .good:
            parts.append("Dışarıda harika bir gün seni bekliyor!")
        case .moderate:
            parts.append("Dışarı çıkmak mümkün ama ideal değil.")
        case .risky:
            parts.append("Riskli saatler var, planını buna göre yap.")
        case .avoid:
            parts.append("Bugün dışarı çıkmaman önerilir, zorlu hava koşulları var.")
        }

        if let bestWindow = recommendation.bestOutdoorWindow {
            parts.append("En rahat dışarı zamanı \(bestWindow.shortDisplayText).")
        }

        let significantRisks = recommendation.risks.filter { $0.severity >= .medium }
        if !significantRisks.isEmpty {
            let riskTitles = significantRisks.map(\.title).joined(separator: ", ")
            parts.append("Dikkat: \(riskTitles).")
        }

        parts.append("Kıyafet önerisi: \(recommendation.outfit.title).")

        return parts.joined(separator: " ")
    }

    private func makeOutfitPlan(
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let preference = profile.notificationPreferences.first { $0.category == .outfitSuggestion }
        let preferredTime = preference?.preferredTime ?? DateComponents(hour: 7, minute: 15)
        guard let fireDate = calendar.nextDate(
            after: calendar.startOfDay(for: now).addingTimeInterval(-1),
            matching: preferredTime,
            matchingPolicy: .nextTime
        ) else {
            return nil
        }

        let outfit = recommendation.outfit
        var parts: [String] = []

        parts.append("\(outfit.items.joined(separator: ", ")).")
        if !outfit.accessories.isEmpty {
            parts.append("Yanına al: \(outfit.accessories.joined(separator: ", ")).")
        }
        if let warning = outfit.warning {
            parts.append("Not: \(warning)")
        }

        return NotificationPlan(
            id: stableID(category: .outfitSuggestion, fireDate: fireDate, calendar: calendar),
            category: .outfitSuggestion,
            fireDate: fireDate,
            title: "Bugün böyle giyin",
            body: parts.joined(separator: " "),
            priority: 70,
            reason: "Günlük kıyafet önerisi."
        )
    }

    private func makeActivityPlan(
        activityRecommendation: ActivityRecommendation,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        let fireDate = activityRecommendation.bestWindow.start
        guard fireDate >= now else {
            return nil
        }

        let activityName = activityRecommendation.activityType.localizedTitle.lowercased()
        let score = activityRecommendation.score.rawValue
        let window = activityRecommendation.bestWindow.shortDisplayText

        let body: String
        if score >= 80 {
            body = "Hava şu anda \(activityName) için çok uygun. \(window) saatleri arası tam zamanı, kaçırma!"
        } else if score >= 60 {
            body = "\(activityName) için uygun bir pencere başladı (\(window)). Şimdi çıkabilirsin."
        } else {
            body = "\(activityName) için günün en iyi zamanı \(window). Fırsat varken değerlendir."
        }

        return NotificationPlan(
            id: stableID(category: .bestRunWindow, fireDate: fireDate, calendar: calendar),
            category: .bestRunWindow,
            fireDate: fireDate,
            title: "\(activityRecommendation.activityType.localizedTitle) zamanı!",
            body: body,
            priority: 80,
            reason: activityRecommendation.reason
        )
    }

    private func makeRiskPlans(
        recommendation: DailyRecommendation,
        enabledCategories: Set<NotificationCategory>,
        now: Date,
        calendar: Calendar
    ) -> [NotificationPlan] {
        let eligible = recommendation.avoidWindows.filter { avoidWindow in
            guard let category = notificationCategory(for: avoidWindow.risk.type),
                  enabledCategories.contains(category),
                  avoidWindow.severity >= .medium,
                  avoidWindow.window.start >= now else {
                return false
            }
            return true
        }

        let grouped = Dictionary(grouping: eligible) { $0.window.start }

        return grouped.compactMap { (startDate, windows) in
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

        let combinedTitle: String
        let combinedBody: String
        let combinedPriority: Int
        let combinedReason: String
        let planID: String

        if sorted.count == 1 {
            let w = sorted[0]
            guard let category = notificationCategory(for: w.risk.type) else { return nil }
            combinedTitle = w.risk.title
            combinedBody = buildSingleRiskBody(avoidWindow: w)
            combinedPriority = priorityForSeverity(w.severity)
            combinedReason = w.reason
            planID = stableID(category: category, fireDate: fireDate, calendar: calendar)
        } else {
            guard let primaryCategory = notificationCategory(for: sorted[0].risk.type) else { return nil }
            let window = first.window.shortDisplayText
            let riskNames = sorted.map { $0.risk.title }
            combinedTitle = "\(riskNames.joined(separator: " ve ")) — \(window)"
            combinedBody = buildCombinedRiskBody(windows: sorted, window: first.window)
            combinedPriority = priorityForSeverity(sorted[0].severity)
            combinedReason = sorted.map(\.reason).joined(separator: "; ")

            let riskTypes = sorted.map { $0.risk.type.rawValue }.sorted().joined(separator: "+")
            let components = calendar.dateComponents([.year, .month, .day], from: fireDate)
            let year = components.year ?? 0
            let month = components.month ?? 0
            let day = components.day ?? 0
            planID = "smart.\(riskTypes).\(year)-\(month)-\(day)"
        }

        return NotificationPlan(
            id: planID,
            category: notificationCategory(for: sorted[0].risk.type) ?? .avoidHeatWindow,
            fireDate: fireDate,
            title: combinedTitle,
            body: combinedBody,
            priority: combinedPriority,
            reason: combinedReason
        )
    }

    private func buildSingleRiskBody(avoidWindow: AvoidWindowRecommendation) -> String {
        let window = avoidWindow.window.shortDisplayText
        switch avoidWindow.risk.type {
        case .heat:
            let advice = heatAdvice(severity: avoidWindow.severity)
            return "\(window) arası \(advice)"
        case .uv:
            return "\(window) arası UV indeksi yüksek. Şapka tak, güneş kremi sür, gölgede kal."
        case .rain:
            return "\(window) arası yağmur bekleniyor. Şemsiyeni al, açık hava planlarını ertele."
        case .wind:
            return "\(window) arası kuvvetli rüzgar var. Bisiklet ve açık alan aktivitelerine dikkat et."
        case .humidity, .cold, .storm, .poorComfort:
            return avoidWindow.reason
        }
    }

    private func buildCombinedRiskBody(windows: [AvoidWindowRecommendation], window: TimeWindow) -> String {
        let windowText = window.shortDisplayText
        let parts = windows.map { riskLine($0) }
        return "\(windowText) saatleri arası: \(parts.joined(separator: " "))"
    }

    private func riskLine(_ avoidWindow: AvoidWindowRecommendation) -> String {
        switch avoidWindow.risk.type {
        case .heat:
            return "hissedilen sıcaklık yükseliyor (\(avoidWindow.severity.localizedTitle))."
        case .uv:
            return "UV indeksi yüksek."
        case .rain:
            return "yağmur bekleniyor."
        case .wind:
            return "kuvvetli rüzgar var."
        case .humidity:
            return "yüksek nem bunaltıcı olabilir."
        case .cold:
            return "soğuk hava etkili."
        case .storm:
            return "fırtına riski var."
        case .poorComfort:
            return "konfor seviyesi düşük."
        }
    }

    private func heatAdvice(severity: RiskLevel) -> String {
        switch severity {
        case .extreme:
            return "hissedilen sıcaklık tehlikeli seviyede. Dışarı çıkmaktan kaçının, bol su için."
        case .high:
            return "hissedilen sıcaklık çok yükselecek. Açık renkli bol giysiler giyin, sık sık su için."
        case .medium:
            return "hissedilen sıcaklık yükseliyor. Gölgede kalın, yanınıza su alın."
        case .low:
            return "hissedilen sıcaklık hafif yükselecek."
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

    private func priorityForSeverity(_ severity: RiskLevel) -> Int {
        switch severity {
        case .extreme:
            100
        case .high:
            95
        case .medium:
            85
        case .low:
            60
        }
    }

    private func deduplicate(_ plans: [NotificationPlan]) -> [NotificationPlan] {
        var seenIDs: Set<String> = []
        var uniquePlans: [NotificationPlan] = []

        for plan in plans.sorted(by: { $0.priority > $1.priority })
            where seenIDs.contains(plan.id) == false {
            seenIDs.insert(plan.id)
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
