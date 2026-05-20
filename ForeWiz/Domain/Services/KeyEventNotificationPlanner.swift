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

        // 1. Best outdoor window
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
                severity: .low
            ))
        }

        // 2. Rain events — doğal dil: "Saat 14:00–16:00 arasında yağmur bekleniyor."
        let rainClusters = clusterHours(todayPoints, where: { $0.precipitationChance ?? 0 >= 0.5 })
        for (index, cluster) in rainClusters.enumerated() {
            let maxChance = cluster.map { $0.precipitationChance ?? 0 }.max() ?? 0
            let severity: DayKeyEvent.EventSeverity = maxChance >= 0.8 ? .high : .moderate
            let startHour = calendar.component(.hour, from: cluster.first!.date)
            let endHour = calendar.component(.hour, from: cluster.last!.date)
            let timeRange = timeText(startHour: startHour, endHour: endHour + 1)
            let description: String
            if severity >= .high {
                description = String(format: L10n.text("keyevent_rain_heavy_desc"), timeRange)
            } else {
                description = String(format: L10n.text("keyevent_rain_light_desc"), timeRange)
            }
            events.append(DayKeyEvent(
                id: "rain-\(index)",
                type: .rain,
                startHour: startHour,
                endHour: endHour + 1,
                title: L10n.text("keyevent_rain_title"),
                description: description,
                symbolName: "cloud.rain.fill",
                severity: severity
            ))
        }

        // 3. Storm / severe weather
        for point in todayPoints {
            guard let risk = point.severeWeatherRisk, risk >= .high else { continue }
            let hour = calendar.component(.hour, from: point.date)
            let severity: DayKeyEvent.EventSeverity = risk == .extreme ? .critical : .high
            let timeText = singleHourText(hour: hour)
            let description: String
            if severity == .critical {
                description = String(format: L10n.text("keyevent_storm_critical_desc"), timeText)
            } else {
                description = String(format: L10n.text("keyevent_storm_desc"), timeText)
            }
            events.append(DayKeyEvent(
                id: "storm-\(hour)",
                type: .storm,
                startHour: hour,
                endHour: hour + 1,
                title: L10n.text("keyevent_storm_title"),
                description: description,
                symbolName: "cloud.bolt.fill",
                severity: severity
            ))
        }

        // 4. Heat events
        let heatClusters = clusterHours(todayPoints, where: { $0.temperatureCelsius >= 33 })
        for (index, cluster) in heatClusters.enumerated() {
            let maxTemp = cluster.map { $0.temperatureCelsius }.max() ?? 0
            let severity: DayKeyEvent.EventSeverity = maxTemp >= 38 ? .critical : .high
            let startHour = calendar.component(.hour, from: cluster.first!.date)
            let endHour = calendar.component(.hour, from: cluster.last!.date)
            let tempText = mapper.temperatureText(maxTemp, unitSystem: unitSystem)
            let timeRange = timeText(startHour: startHour, endHour: endHour + 1)
            let description: String
            if severity == .critical {
                description = String(format: L10n.text("keyevent_heat_critical_desc"), timeRange, tempText)
            } else {
                description = String(format: L10n.text("keyevent_heat_desc"), timeRange, tempText)
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

        // 5. Strong wind
        let windClusters = clusterHours(todayPoints, where: { $0.windSpeedKph ?? 0 >= 40 })
        for (index, cluster) in windClusters.enumerated() {
            let maxWind = cluster.map { $0.windSpeedKph ?? 0 }.max() ?? 0
            let severity: DayKeyEvent.EventSeverity = maxWind >= 60 ? .high : .moderate
            let startHour = calendar.component(.hour, from: cluster.first!.date)
            let endHour = calendar.component(.hour, from: cluster.last!.date)
            let timeRange = timeText(startHour: startHour, endHour: endHour + 1)
            let description: String
            if severity >= .high {
                description = String(format: L10n.text("keyevent_wind_strong_desc"), timeRange, Int(maxWind))
            } else {
                description = String(format: L10n.text("keyevent_wind_desc"), timeRange, Int(maxWind))
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

        // 6. High UV
        let uvClusters = clusterHours(todayPoints, where: { $0.uvIndex ?? 0 >= 7 })
        for (index, cluster) in uvClusters.enumerated() {
            let maxUv = cluster.map { $0.uvIndex ?? 0 }.max() ?? 0
            let severity: DayKeyEvent.EventSeverity = maxUv >= 10 ? .high : .moderate
            let startHour = calendar.component(.hour, from: cluster.first!.date)
            let endHour = calendar.component(.hour, from: cluster.last!.date)
            let timeRange = timeText(startHour: startHour, endHour: endHour + 1)
            let description = String(format: L10n.text("keyevent_uv_desc"), timeRange, maxUv)
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

        // Sort by severity descending, then by start hour
        return events.sorted {
            if $0.severity != $1.severity {
                return $0.severity > $1.severity
            }
            return $0.startHour < $1.startHour
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
            guard let fireDate = calendar.date(
                bySettingHour: event.startHour,
                minute: 0,
                second: 0,
                of: now
            ) else { return nil }

            let adjustedDate = fireDate.addingTimeInterval(-30 * 60) // 30 minutes before
            guard adjustedDate > now else { return nil } // already passed

            // Moderate+ events get notified; low severity (best window) only if not already covered
            let priority: Int
            switch event.severity {
            case .critical: priority = 95
            case .high: priority = 85
            case .moderate: priority = 70
            case .low: priority = 50
            }

            return NotificationPlan(
                id: "keyevent.\(event.id)",
                category: .keyEvent,
                fireDate: adjustedDate,
                title: event.title,
                body: event.description,
                priority: priority,
                reason: event.description
            )
        }
    }

    // MARK: - Helpers

    /// Natural time range text: "14:00–16:00"
    private static func timeText(startHour: Int, endHour: Int) -> String {
        if endHour - startHour <= 1 {
            return singleHourText(hour: startHour)
        }
        return String(format: "%02d:00–%02d:00", startHour, endHour)
    }

    /// Natural single hour text: "15:00"
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
