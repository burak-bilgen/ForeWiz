import Foundation

// MARK: - Key Event Notification Planner

/// Generates `DayKeyEvent`s from hourly weather data and converts them into
/// push notification plans scheduled near the event start time.
enum KeyEventNotificationPlanner {

    // MARK: - Public API

    /// Produces `DayKeyEvent` models from hourly data and recommendation.
    static func makeKeyEvents(
        from hourlyPoints: [HourlyWeatherPoint],
        recommendation: DailyRecommendation,
        unitSystem: UnitSystem = .current,
        mapper: WeatherPresentationMapper = WeatherPresentationMapper()
    ) -> [DayKeyEvent] {
        let todayPoints = hourlyPoints.filter { Calendar.current.isDateInToday($0.date) }
        guard !todayPoints.isEmpty else { return [] }

        var events: [DayKeyEvent] = []
        let calendar = Calendar.current

        // 1. Best outdoor window (info severity - always shown)
        if let window = recommendation.bestOutdoorWindow {
            let startHour = calendar.component(.hour, from: window.start)
            let endHour = calendar.component(.hour, from: window.end)
            events.append(DayKeyEvent(
                id: "best-window",
                type: .bestWindow,
                startHour: startHour,
                endHour: endHour,
                title: L10n.text("keyevent_best_window_title"),
                description: L10n.text("keyevent_best_window_desc"),
                symbolName: "checkmark.circle.fill",
                severity: .info
            ))
        }

        // 2. Rain / Heavy Rain - tüm yağmur saatlerini cluster et (thunderstorm hariç - storm event'inde)
        let rainHours = todayPoints.filter {
            !isThunderstormCondition($0.conditionCode) &&
            ($0.precipitationChance ?? 0 >= 0.5 || isRainCondition($0.conditionCode))
        }
        if !rainHours.isEmpty {
            let sortedRainHours = rainHours.sorted { $0.date < $1.date }
            let maxChance = sortedRainHours.map { $0.precipitationChance ?? 0 }.max() ?? 0
            let totalMm = sortedRainHours.map { $0.precipitationAmountMm ?? 0 }.reduce(0, +)
            let severity: DayKeyEvent.EventSeverity = maxChance >= 0.8 ? .high : .moderate
            let isHeavy = totalMm >= 10.0 || severity >= .high
            guard let firstRain = sortedRainHours.first, let lastRain = sortedRainHours.last else { return events }
            let startHour = calendar.component(.hour, from: firstRain.date)
            let endHour = calendar.component(.hour, from: lastRain.date) + 1
            let timeRange = timeText(startHour: startHour, endHour: endHour)

            let description: String
            if isHeavy {
                description = String(format: L10n.text("keyevent_rain_heavy_desc"), timeRange)
            } else {
                description = String(format: L10n.text("keyevent_rain_light_desc"), timeRange)
            }

            events.append(DayKeyEvent(
                id: "rain",
                type: isHeavy ? .heavyRain : .rain,
                startHour: startHour,
                endHour: endHour,
                title: L10n.text(isHeavy ? "keyevent_heavyrain_title" : "keyevent_rain_title"),
                description: description,
                symbolName: isHeavy ? "cloud.heavyrain.fill" : "cloud.rain.fill",
                severity: severity
            ))
        }

        // 3. Storm / severe weather - cluster consecutive hours
        let stormClusters = clusterHours(todayPoints) { point in
            // Catch thunderstorm by condition code, OR severe weather risk
            if isThunderstormCondition(point.conditionCode) { return true }
            guard let risk = point.severeWeatherRisk else { return false }
            return risk >= .high
        }
        for (index, cluster) in stormClusters.enumerated() {
            guard let first = cluster.first, let last = cluster.last else { continue }
            let maxRisk = cluster.compactMap { $0.severeWeatherRisk }.max() ?? .high
            let severity: DayKeyEvent.EventSeverity = maxRisk == .extreme ? .critical : .high
            let startHour = calendar.component(.hour, from: first.date)
            let endHour = calendar.component(.hour, from: last.date) + 1
            let timeRange = timeText(startHour: startHour, endHour: endHour)

            let description: String
            if severity == .critical {
                description = String(format: L10n.text("keyevent_storm_critical_desc"), timeRange)
            } else {
                description = String(format: L10n.text("keyevent_storm_desc"), timeRange)
            }
            events.append(DayKeyEvent(
                id: "storm-\(index)",
                type: .storm,
                startHour: startHour,
                endHour: endHour,
                title: L10n.text("keyevent_storm_title"),
                description: description,
                symbolName: "cloud.bolt.fill",
                severity: severity
            ))
        }

        // 4. Cold events (temp <= 5°C)
        let coldClusters = clusterHours(todayPoints, where: { $0.temperatureCelsius <= 5 })
        for (index, cluster) in coldClusters.enumerated() {
            guard let first = cluster.first, let last = cluster.last else { continue }
            let minTemp = cluster.map { $0.temperatureCelsius }.min() ?? 0
            let severity: DayKeyEvent.EventSeverity = minTemp <= -5 ? .high : (minTemp <= 0 ? .moderate : .low)
            let startHour = calendar.component(.hour, from: first.date)
            let endHour = calendar.component(.hour, from: last.date) + 1
            let timeRange = timeText(startHour: startHour, endHour: endHour)

            let description: String
            if severity >= .high {
                description = String(format: L10n.text("keyevent_cold_extreme_desc"), timeRange)
            } else {
                description = String(format: L10n.text("keyevent_cold_desc"), timeRange)
            }
            events.append(DayKeyEvent(
                id: "cold-\(index)",
                type: .cold,
                startHour: startHour,
                endHour: endHour,
                title: L10n.text("keyevent_cold_title"),
                description: description,
                symbolName: "snowflake",
                severity: severity
            ))
        }

        // 5. Snow events (condition code)
        if let snowCluster = makeConditionEvent(
            from: todayPoints,
            conditionCheck: isSnowCondition,
            idPrefix: "snow",
            eventType: .snow,
            titleKey: "keyevent_snow_title",
            descKey: "keyevent_snow_desc",
            timeArg: true,
            symbolName: "cloud.snow.fill",
            moderateSeverity: .moderate
        ) {
            events.append(snowCluster)
        }

        // 6. Fog events (condition code)
        if let fogEvent = makeConditionEvent(
            from: todayPoints,
            conditionCheck: isFogCondition,
            idPrefix: "fog",
            eventType: .fog,
            titleKey: "keyevent_fog_title",
            descKey: "keyevent_fog_desc",
            timeArg: true,
            symbolName: "cloud.fog.fill",
            moderateSeverity: .moderate
        ) {
            events.append(fogEvent)
        }

        // 7. Heat events
        let heatClusters = clusterHours(todayPoints, where: { $0.temperatureCelsius >= 33 })
        for (index, cluster) in heatClusters.enumerated() {
            guard let first = cluster.first, let last = cluster.last else { continue }
            let maxTemp = cluster.map { $0.temperatureCelsius }.max() ?? 0
            let severity: DayKeyEvent.EventSeverity = maxTemp >= 38 ? .critical : .high
            let startHour = calendar.component(.hour, from: first.date)
            let endHour = calendar.component(.hour, from: last.date)
            let timeRange = timeText(startHour: startHour, endHour: endHour + 1)
            let description: String
            if severity == .critical {
                description = String(format: L10n.text("keyevent_heat_critical_desc"), timeRange)
            } else {
                description = String(format: L10n.text("keyevent_heat_desc"), timeRange)
            }
            events.append(DayKeyEvent(
                id: "heat-\(index)",
                type: .heat,
                startHour: startHour,
                endHour: endHour + 1,
                title: L10n.text("keyevent_heat_title"),
                description: description,
                symbolName: "thermometer.sun.fill",
                severity: severity
            ))
        }

        // 8. Strong wind
        let windClusters = clusterHours(todayPoints, where: { $0.windSpeedKph ?? 0 >= 40 })
        for (index, cluster) in windClusters.enumerated() {
            guard let first = cluster.first, let last = cluster.last else { continue }
            let maxWind = cluster.map { $0.windSpeedKph ?? 0 }.max() ?? 0
            let severity: DayKeyEvent.EventSeverity = maxWind >= 60 ? .high : .moderate
            let startHour = calendar.component(.hour, from: first.date)
            let endHour = calendar.component(.hour, from: last.date)
            let timeRange = timeText(startHour: startHour, endHour: endHour + 1)
            let description: String
            if severity >= .high {
                description = String(format: L10n.text("keyevent_wind_strong_desc"), timeRange)
            } else {
                description = String(format: L10n.text("keyevent_wind_desc"), timeRange)
            }
            events.append(DayKeyEvent(
                id: "wind-\(index)",
                type: .strongWind,
                startHour: startHour,
                endHour: endHour + 1,
                title: L10n.text("keyevent_wind_title"),
                description: description,
                symbolName: "wind",
                severity: severity
            ))
        }

        // 9. High UV
        let uvClusters = clusterHours(todayPoints, where: { $0.uvIndex ?? 0 >= 7 })
        for (index, cluster) in uvClusters.enumerated() {
            guard let first = cluster.first, let last = cluster.last else { continue }
            let maxUv = cluster.map { $0.uvIndex ?? 0 }.max() ?? 0
            let severity: DayKeyEvent.EventSeverity = maxUv >= 10 ? .high : .moderate
            let startHour = calendar.component(.hour, from: first.date)
            let endHour = calendar.component(.hour, from: last.date)
            let timeRange = timeText(startHour: startHour, endHour: endHour + 1)
            let description = String(format: L10n.text("keyevent_uv_desc"), timeRange)
            events.append(DayKeyEvent(
                id: "uv-\(index)",
                type: .highUV,
                startHour: startHour,
                endHour: endHour + 1,
                title: L10n.text("keyevent_uv_title"),
                description: description,
                symbolName: "sun.max.fill",
                severity: severity
            ))
        }

        // 10. Improving conditions (rain/snow clearing up) - positive event
        if let improvingEvent = detectImprovingConditions(
            todayPoints: todayPoints,
            calendar: calendar,
            mapper: mapper,
            unitSystem: unitSystem
        ) {
            events.append(improvingEvent)
        }

        // Sort by severity (critical first), then positive events after warnings,
        // then by start hour. Info events go last.
        return events.sorted { a, b in
            // Positive events always go after warnings
            if a.isPositive != b.isPositive {
                return !a.isPositive // warnings first
            }
            if a.severity != b.severity {
                return a.severity > b.severity
            }
            return a.startHour < b.startHour
        }
    }

    /// Converts a list of `DayKeyEvent`s into push notification plans,
    /// scheduled 30 minutes before each event starts.
    static func makeNotificationPlans(
        from keyEvents: [DayKeyEvent],
        now: Date,
        calendar: Calendar = .current
    ) -> [NotificationPlan] {
        keyEvents.compactMap { event -> NotificationPlan? in
            // Don't send notifications for info events or positive events
            guard event.severity >= .low, !event.isPositive else { return nil }

            guard let fireDate = calendar.date(
                bySettingHour: event.startHour,
                minute: 0,
                second: 0,
                of: now
            ) else { return nil }

            let adjustedDate = fireDate.addingTimeInterval(-30 * 60) // 30 minutes before
            guard adjustedDate > now else { return nil } // already passed

            let priority: Int
            switch event.severity {
            case .critical: priority = 95
            case .high: priority = 85
            case .moderate: priority = 70
            case .low: priority = 50
            case .info: return nil // no notifications for info-level events
            }

            return NotificationPlan(
                id: "keyevent.\\(event.id)",
                category: .keyEvent,
                fireDate: adjustedDate,
                title: event.title,
                body: event.description,
                priority: priority,
                reason: event.description
            )
        }
    }

    // MARK: - Condition Helpers

    /// Creates a single clustered event for a condition-code-based weather type (snow, fog, etc.)
    private static func makeConditionEvent(
        from todayPoints: [HourlyWeatherPoint],
        conditionCheck: (String?) -> Bool,
        idPrefix: String,
        eventType: DayKeyEvent.EventType,
        titleKey: String,
        descKey: String,
        timeArg: Bool,
        symbolName: String,
        moderateSeverity: DayKeyEvent.EventSeverity
    ) -> DayKeyEvent? {
        let matching = todayPoints.filter { conditionCheck($0.conditionCode) }
        guard !matching.isEmpty else { return nil }

        let cal = Calendar.current
        guard let first = matching.first, let last = matching.last else { return nil }
        let startHour = cal.component(.hour, from: first.date)
        let endHour = cal.component(.hour, from: last.date) + 1
        let timeRange = timeText(startHour: startHour, endHour: endHour)

        let description: String
        if timeArg {
            description = String(format: L10n.text(descKey), timeRange)
        } else {
            description = L10n.text(descKey)
        }

        return DayKeyEvent(
            id: idPrefix,
            type: eventType,
            startHour: startHour,
            endHour: endHour,
            title: L10n.text(titleKey),
            description: description,
            symbolName: symbolName,
            severity: moderateSeverity
        )
    }

    /// Detects a positive "clearing up" event: rain/snow in the morning, clear afternoon
    private static func detectImprovingConditions(
        todayPoints: [HourlyWeatherPoint],
        calendar: Calendar,
        mapper: WeatherPresentationMapper,
        unitSystem: UnitSystem
    ) -> DayKeyEvent? {
        let sorted = todayPoints.sorted { $0.date < $1.date }
        guard sorted.count >= 6 else { return nil }

        // Morning hours: 6-12
        let morning = sorted.filter { 6..<12 ~= calendar.component(.hour, from: $0.date) }
        // Afternoon hours: 12-17
        let afternoon = sorted.filter { 12..<18 ~= calendar.component(.hour, from: $0.date) }

        guard !morning.isEmpty, !afternoon.isEmpty else { return nil }

        let morningRain = morning.filter { isRainCondition($0.conditionCode) || ($0.precipitationChance ?? 0) >= 0.5 }
        let afternoonRain = afternoon.filter { isRainCondition($0.conditionCode) || ($0.precipitationChance ?? 0) >= 0.5 }

        // Transition: rain/snow clearing → drier afternoon
        let morningHasRain = !morningRain.isEmpty
        let afternoonClearing = afternoonRain.count <= afternoon.count / 3 // 1/3 or fewer rain hours

        guard morningHasRain && afternoonClearing else { return nil }

        // Find the transition point
        guard let lastMorningRainPoint = morningRain.last else { return nil }
        let lastMorningRainHour = calendar.component(.hour, from: lastMorningRainPoint.date)
        let firstClearAfternoon = afternoon.first { !isRainCondition($0.conditionCode) && ($0.precipitationChance ?? 0) < 0.4 }
        guard let clearAfternoon = firstClearAfternoon else { return nil }
        let clearHour = calendar.component(.hour, from: clearAfternoon.date)

        return DayKeyEvent(
            id: "improving",
            type: .improving,
            startHour: lastMorningRainHour,
            endHour: clearHour + 1,
            title: L10n.text("keyevent_improving_title"),
            description: String(format: L10n.text("keyevent_improving_desc"), timeText(startHour: lastMorningRainHour, endHour: clearHour + 1)),
            symbolName: "cloud.sun.fill",
            severity: .info
        )
    }

    // MARK: - Condition Checkers

    private static func isRainCondition(_ code: String?) -> Bool {
        guard let code = code?.lowercased() else { return false }
        return code.contains("rain")
            || code.contains("drizzle")
            || code.contains("shower")
    }

    private static func isThunderstormCondition(_ code: String?) -> Bool {
        guard let code = code?.lowercased() else { return false }
        return code.contains("thunderstorm")
            || code.contains("tstorm")
            || code.contains("lightning")
    }

    private static func isSnowCondition(_ code: String?) -> Bool {
        guard let code = code?.lowercased() else { return false }
        return code.contains("snow")
            || code.contains("sleet")
            || code.contains("blizzard")
            || code.contains("wintry")
    }

    private static func isFogCondition(_ code: String?) -> Bool {
        guard let code = code?.lowercased() else { return false }
        return code.contains("fog")
            || code.contains("mist")
            || code.contains("haze")
            || code == "foggy"
            || code == "smoky"
    }

    // MARK: - Formatting Helpers

    private static func timeText(startHour: Int, endHour: Int) -> String {
        if endHour - startHour <= 1 {
            return singleHourText(hour: startHour)
        }
        return String(format: "%02d:00–%02d:00", startHour, endHour)
    }

    private static func singleHourText(hour: Int) -> String {
        return String(format: "%02d:00", hour)
    }

    /// Groups consecutive hours that satisfy the given predicate.
    static func clusterHours(_ points: [HourlyWeatherPoint], where predicate: (HourlyWeatherPoint) -> Bool) -> [[HourlyWeatherPoint]] {
        let sorted = points.sorted { $0.date < $1.date }
        var clusters: [[HourlyWeatherPoint]] = []
        var currentCluster: [HourlyWeatherPoint] = []

        for point in sorted {
            if predicate(point) {
                currentCluster.append(point)
            } else if !currentCluster.isEmpty {
                clusters.append(currentCluster)
                currentCluster = []
            }
        }

        if !currentCluster.isEmpty {
            clusters.append(currentCluster)
        }

        return clusters
    }
}
