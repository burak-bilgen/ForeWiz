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
           isWorthNotifying(plan: plan, calendar: calendar) {
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
        candidates.append(
            contentsOf: makeImmediateRiskPlans(
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
            .filter { isWorthNotifying(plan: $0, calendar: calendar) }

        let sorted = filtered.sorted { p0, p1 in
            if p0.priority == p1.priority {
                if p0.fireDate == p1.fireDate {
                    return p0.category.rawValue < p1.category.rawValue
                }
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
        let preferredTime = preference?.preferredTime ?? DateComponents(hour: 7, minute: 30)

        guard let fireDate = calendar.nextDate(
            after: now,
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
            title: copy(tr: "Bugünün hava planı hazır", en: "Today's weather plan is ready"),
            body: body,
            priority: 70,
            reason: L10n.text("notification_morning_reason")
        )
    }

    private func buildSmartMorningBody(recommendation: DailyRecommendation) -> String {
        let opening: String
        switch recommendation.outdoorDecision {
        case .good:
            opening = copy(
                tr: "Bugün dış plan için rahat görünüyor.",
                en: "Today looks comfortable for outdoor plans."
            )
        case .moderate:
            opening = copy(
                tr: "Dışarı çıkılır, ama küçük önlem iyi olur.",
                en: "Outdoor plans are fine today, with a little preparation."
            )
        case .risky:
            opening = copy(
                tr: "Bugün dış planı dikkatli kurmak daha iyi.",
                en: "Build today's outdoor plan carefully."
            )
        case .avoid:
            opening = copy(
                tr: "Bugün dış planı kısa tutmak daha güvenli.",
                en: "It is safer to keep outdoor plans short today."
            )
        }

        var sentences = [opening]
        if let bestWindow = recommendation.bestOutdoorWindow {
            sentences.append(
                copy(
                    tr: "En rahat aralık \(bestWindow.shortDisplayText).",
                    en: "The best window is \(bestWindow.shortDisplayText)."
                )
            )
        }

        if let risk = dominantRisk(in: recommendation), risk.severity >= .high {
            sentences.append(
                copy(
                    tr: "\(risk.title) öne çıkıyor; \(actionText(for: risk))",
                    en: "\(risk.title) stands out; \(actionText(for: risk))"
                )
            )
        }

        return sentences.joined(separator: " ")
    }

    private func makeOutfitPlan(
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
        ) else {
            return nil
        }

        let outfit = recommendation.outfit
        let body = buildOutfitBody(outfit)

        return NotificationPlan(
            id: stableID(category: .outfitSuggestion, fireDate: fireDate, calendar: calendar),
            category: .outfitSuggestion,
            fireDate: fireDate,
            title: copy(tr: "Bugün ne giyilir?", en: "What to wear today"),
            body: body,
            priority: 60,
            reason: L10n.text("notification_outfit_reason")
        )
    }

    private func buildOutfitBody(_ outfit: OutfitRecommendation) -> String {
        let items = outfit.items.prefix(3).joined(separator: ", ")
        let accessories = outfit.accessories.prefix(2).joined(separator: ", ")

        var sentences: [String] = []
        if items.isEmpty {
            sentences.append(outfit.title)
        } else {
            sentences.append(
                copy(
                    tr: "\(items) iyi olur.",
                    en: "\(items) should work well."
                )
            )
        }

        if accessories.isEmpty == false {
            sentences.append(
                copy(
                    tr: "\(accessories) yanına al.",
                    en: "Bring \(accessories)."
                )
            )
        }

        if let warning = outfit.warning {
            sentences.append(warning)
        }

        return sentences.joined(separator: " ")
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
        let activityTitle = activityRecommendation.activityType.localizedTitle
        let body = buildActivityBody(
            activityTitle: activityTitle,
            time: time,
            score: activityRecommendation.score.rawValue
        )

        return NotificationPlan(
            id: stableID(category: .bestRunWindow, fireDate: fireDate, calendar: calendar),
            category: .bestRunWindow,
            fireDate: fireDate,
            title: copy(
                tr: "\(activityTitle) için iyi aralık",
                en: "Best \(activityTitle) window"
            ),
            body: body,
            priority: 80,
            reason: activityRecommendation.reason
        )
    }

    private func buildActivityBody(activityTitle: String, time: String, score: Int) -> String {
        if score >= 80 {
            return copy(
                tr: "\(time) arası gerçekten iyi görünüyor. Skor \(score)/100; planını bu aralığa al.",
                en: "\(time) looks genuinely good. Score \(score)/100; use this window if you can."
            )
        }

        if score >= 60 {
            return copy(
                tr: "\(time) arası daha uygun. Skor \(score)/100; \(activityTitle) planını bu saate çek.",
                en: "\(time) is the better option. Score \(score)/100; move your \(activityTitle) plan there."
            )
        }

        return copy(
            tr: "Bugünün en makul aralığı \(time). Skor \(score)/100; kısa ve esnek planla.",
            en: "The least risky window today is \(time). Score \(score)/100; keep it short and flexible."
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

        let grouped = Dictionary(grouping: eligible) { window in
            fireDate(for: window, now: now, calendar: calendar)
        }

        return grouped.compactMap { startDate, windows in
            makeCombinedRiskPlan(windows: windows, fireDate: startDate, calendar: calendar)
        }
        .sorted { p0, p1 in
            if p0.fireDate == p1.fireDate {
                return p0.category.rawValue < p1.category.rawValue
            }
            return p0.fireDate < p1.fireDate
        }
    }

    private func makeImmediateRiskPlans(
        recommendation: DailyRecommendation,
        enabledCategories: Set<NotificationCategory>,
        now: Date,
        calendar: Calendar
    ) -> [NotificationPlan] {
        let fireDate = calendar.date(byAdding: .minute, value: 5, to: now) ?? now.addingTimeInterval(5 * 60)

        return recommendation.risks
            .filter { $0.severity >= .high }
            .compactMap { risk -> NotificationPlan? in
                guard let category = notificationCategory(for: risk.type),
                      enabledCategories.contains(category) else {
                    return nil
                }

                return NotificationPlan(
                    id: stableID(category: category, fireDate: fireDate, calendar: calendar) + ".urgent.\(risk.type.rawValue)",
                    category: category,
                    fireDate: fireDate,
                    title: immediateRiskTitle(for: risk),
                    body: buildImmediateRiskBody(risk),
                    priority: priorityForSeverity(risk.severity),
                    reason: risk.message
                )
            }
    }

    private func makeCombinedRiskPlan(
        windows: [AvoidWindowRecommendation],
        fireDate: Date,
        calendar: Calendar
    ) -> NotificationPlan? {
        guard windows.isEmpty == false else { return nil }
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
        let risks = windows.prefix(2).map { $0.risk.title }.joined(separator: ", ")
        let primary = windows[0].risk

        return copy(
            tr: "\(time) arası \(risks) öne çıkıyor. \(actionText(for: primary))",
            en: "\(risks) stands out around \(time). \(actionText(for: primary))"
        )
    }

    private func immediateRiskTitle(for risk: WeatherRisk) -> String {
        copy(
            tr: "Şimdi dikkat: \(risk.title)",
            en: "Heads up: \(risk.title)"
        )
    }

    private func buildImmediateRiskBody(_ risk: WeatherRisk) -> String {
        copy(
            tr: "\(risk.message) \(actionText(for: risk))",
            en: "\(risk.message) \(actionText(for: risk))"
        )
    }

    private func dominantRisk(in recommendation: DailyRecommendation) -> WeatherRisk? {
        recommendation.risks
            .sorted { lhs, rhs in lhs.severity.rawValue > rhs.severity.rawValue }
            .first { $0.severity >= .medium }
    }

    private func actionText(for risk: WeatherRisk) -> String {
        switch risk.type {
        case .heat:
            copy(
                tr: "gölge, su ve kısa molalarla ilerle.",
                en: "stick to shade, water and short breaks."
            )
        case .uv:
            copy(
                tr: "güneş kremi, şapka ve gölge planı iyi olur.",
                en: "use sunscreen, a hat and a shade plan."
            )
        case .rain:
            copy(
                tr: "şemsiyeyi al veya planı kapalı alana çek.",
                en: "bring an umbrella or move the plan indoors."
            )
        case .wind, .storm:
            copy(
                tr: "açık alanda uzun kalma ve esnek plan yap.",
                en: "avoid long exposed outdoor time and keep plans flexible."
            )
        case .humidity:
            copy(
                tr: "tempoyu düşür ve suyu yanında tut.",
                en: "slow the pace and keep water nearby."
            )
        case .cold:
            copy(
                tr: "katmanlı giyin ve rüzgara açık yerde uzun kalma.",
                en: "dress in layers and avoid staying exposed too long."
            )
        case .poorComfort:
            copy(
                tr: "dışarıdaki süreyi kısa tutmak daha mantıklı.",
                en: "keeping outdoor time short is the better call."
            )
        case .pollen:
            copy(
                tr: "alerjin varsa ilacını ve gözlüğünü hazır tut.",
                en: "if you have allergies, keep medication and sunglasses ready."
            )
        case .airQuality:
            copy(
                tr: "hassassan dış planı kısalt ve yoğun aktiviteden kaçın.",
                en: "if you are sensitive, shorten outdoor plans and avoid intense activity."
            )
        }
    }

    private func copy(tr: String, en: String) -> String {
        L10n.currentLanguageCode == "tr" ? tr : en
    }

    private func isWorthNotifying(plan: NotificationPlan, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: plan.fireDate)
        
        // Late night: only high-priority notifications
        if hour >= 22 || hour < 6 {
            return plan.priority >= 90
        }

        // Midday (12-14): suppress low-priority notifications
        if hour >= 12 && hour < 14 {
            return plan.priority >= 60
        }

        // Morning (7-9) and evening (17-19): allow all
        return true
    }

    private func fireDate(
        for window: AvoidWindowRecommendation,
        now: Date,
        calendar: Calendar
    ) -> Date {
        // Lead time varies by risk severity
        let warningLeadMinutes: Int
        switch window.severity {
        case .extreme:
            warningLeadMinutes = 60 // warn 1 hour in advance
        case .high:
            warningLeadMinutes = 45
        case .medium:
            warningLeadMinutes = 30
        case .low:
            warningLeadMinutes = 15
        }

        let leadDate = calendar.date(
            byAdding: .minute,
            value: -warningLeadMinutes,
            to: window.window.start
        ) ?? window.window.start

        return max(leadDate, now)
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
        case .wind, .storm: return .windWarning
        case .pollen: return .pollenWarning
        case .airQuality: return .airQualityWarning
        case .humidity, .cold, .poorComfort: return nil
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
