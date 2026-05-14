import Foundation

/// Factory for creating HomeViewState from domain models.
///
/// Extracts all presentation logic from HomeViewModel, following the
/// Factory pattern for testability and separation of concerns.
@MainActor
final class HomeViewStateFactory {
    private let dateProvider: DateProvider
    private let activityWindowScoringEngine: ActivityWindowScoringEngine
    
    init(
        dateProvider: DateProvider = SystemDateProvider(),
        activityWindowScoringEngine: ActivityWindowScoringEngine = DefaultActivityWindowScoringEngine()
    ) {
        self.dateProvider = dateProvider
        self.activityWindowScoringEngine = activityWindowScoringEngine
    }
    
    /// Creates complete view state from a recommendation result.
    func makeViewState(
        from result: HomeRecommendationResult,
        profile: UserComfortProfile,
        unitSystem: UnitSystem = .current
    ) -> HomeViewState {
        HomeViewState(
            recommendation: result.recommendation,
            assistant: makeAssistantState(from: result),
            plan: makePlanState(from: result),
            currentWeather: makeCurrentWeatherState(from: result.currentWeather, dailyPoints: result.dailyPoints, unitSystem: unitSystem),
            dailyForecasts: makeDailyForecasts(from: result.dailyPoints, unitSystem: unitSystem),
            hourlyScores: makeHourlyScores(from: result.hourlyPoints, profile: profile, unitSystem: unitSystem),
            lastUpdatedText: lastUpdatedText(for: result.weatherFetchedAt),
            isUsingCachedWeather: result.isUsingCachedWeather,
            warningMessage: result.warningMessage,
            attribution: result.attribution
        )
    }
}

// MARK: - Assistant State

private extension HomeViewStateFactory {
    func makeAssistantState(from result: HomeRecommendationResult) -> HomeAssistantViewState {
        let recommendation = result.recommendation
        let topAlert = result.alerts.sorted { lhs, rhs in
            if lhs.severity == rhs.severity {
                return lhs.summary < rhs.summary
            }
            return lhs.severity > rhs.severity
        }.first
        
        let criticalAlert: HomeAssistantSignal? = topAlert.flatMap { alert in
            guard alert.severity >= .high else { return nil }
            return HomeAssistantSignal(
                id: "official-alert",
                icon: "exclamationmark.triangle.fill",
                title: L10n.text("official_alert"),
                subtitle: alert.summary,
                hint: alert.region.map { "\($0) - \(alert.source)" } ?? alert.source,
                tone: .danger
            )
        }
        
        let (headline, symbolName, tone) = resolveAssistantPresentation(
            recommendation: recommendation,
            criticalAlert: criticalAlert,
            topRisk: recommendation.risks.first { $0.severity >= .high }
        )
        
        return HomeAssistantViewState(
            headline: headline,
            summary: makeAssistantSummary(for: recommendation),
            primaryActionTitle: primaryActionTitle(for: recommendation),
            primaryActionDetail: primaryActionDetail(for: recommendation),
            symbolName: symbolName,
            tone: tone,
            criticalAlert: criticalAlert
        )
    }
    
    func resolveAssistantPresentation(
        recommendation: DailyRecommendation,
        criticalAlert: HomeAssistantSignal?,
        topRisk: WeatherRisk?
    ) -> (headline: String, symbolName: String, tone: HomeAssistantTone) {
        let isTomorrow = recommendation.isTomorrowsRecommendation
        let prefix = isTomorrow ? L10n.text("tomorrow_prefix") + " " : ""
        
        if criticalAlert != nil {
            return (
                prefix + L10n.text("official_weather_alert"),
                "exclamationmark.triangle.fill",
                .danger
            )
        }
        
        if let risk = topRisk {
            return (
                prefix + L10n.text("adjust_the_plan_for_safety"),
                iconName(for: risk.type),
                .danger
            )
        }
        
        let (headline, symbol, tone) = decisionPresentation(for: recommendation.outdoorDecision, isTomorrow: isTomorrow)
        return (headline, symbol, tone)
    }
    
    func decisionPresentation(for decision: OutdoorDecision, isTomorrow: Bool) -> (String, String, HomeAssistantTone) {
        let prefix = isTomorrow ? L10n.text("tomorrow_prefix") + " " : ""
        
        switch decision {
        case .good:
            return (prefix + L10n.text("clear_outdoor_day"), "checkmark.seal.fill", .good)
        case .moderate:
            return (prefix + L10n.text("good_to_go_with_light"), "sparkles", .info)
        case .risky:
            return (prefix + L10n.text("plan_carefully"), "exclamationmark.triangle.fill", .caution)
        case .avoid:
            return (prefix + L10n.text("better_to_postpone_outdoor_plans"), "xmark.octagon.fill", .danger)
        }
    }
    
    func makeAssistantSummary(for recommendation: DailyRecommendation) -> String {
        if let risk = recommendation.risks.first(where: { $0.severity >= .high }) {
            return String(format: L10n.text("home_assistant_summary_risk_format"), risk.title, actionText(for: risk))
        }
        
        if let bestWindow = recommendation.bestOutdoorWindow {
            return makeSummaryWithWindow(recommendation.outdoorDecision, bestWindow: bestWindow)
        }
        
        return makeSummaryWithoutWindow(recommendation.outdoorDecision)
    }
    
    func makeSummaryWithWindow(_ decision: OutdoorDecision, bestWindow: TimeWindow) -> String {
        switch decision {
        case .good:
            return String(format: L10n.text("home_assistant_summary_good_format"), bestWindow.shortDisplayText)
        case .moderate:
            return String(format: L10n.text("home_assistant_summary_moderate_format"), bestWindow.shortDisplayText)
        case .risky:
            return String(format: L10n.text("home_assistant_summary_risky_format"), bestWindow.shortDisplayText)
        case .avoid:
            return L10n.text("home_assistant_summary_avoid")
        }
    }
    
    func makeSummaryWithoutWindow(_ decision: OutdoorDecision) -> String {
        switch decision {
        case .good:
            return L10n.text("home_assistant_summary_good_no_window")
        case .moderate:
            return L10n.text("home_assistant_summary_moderate_no_window")
        case .risky:
            return L10n.text("home_assistant_summary_risky_no_window")
        case .avoid:
            return L10n.text("home_assistant_summary_avoid")
        }
    }
    
    func primaryActionTitle(for recommendation: DailyRecommendation) -> String {
        switch recommendation.outdoorDecision {
        case .avoid:
            return L10n.text("home_assistant_action_indoor_title")
        default:
            return recommendation.bestOutdoorWindow != nil
                ? L10n.text("home_assistant_action_window_title")
                : L10n.text("home_assistant_action_flexible_title")
        }
    }
    
    func primaryActionDetail(for recommendation: DailyRecommendation) -> String {
        if recommendation.outdoorDecision == .avoid {
            return L10n.text("home_assistant_action_indoor_detail")
        }
        
        return recommendation.bestOutdoorWindow?.shortDisplayText
            ?? L10n.text("home_assistant_action_flexible_detail")
    }
    
    func actionText(for risk: WeatherRisk) -> String {
        switch risk.type {
        case .heat: return L10n.text("stick_to_shade_water_and")
        case .uv: return L10n.text("use_sunscreen_a_hat_and")
        case .rain: return L10n.text("bring_an_umbrella_or_move")
        case .wind, .storm: return L10n.text("avoid_long_exposed_outdoor_time")
        case .humidity: return L10n.text("slow_the_pace_and_keep")
        case .cold: return L10n.text("dress_in_layers_and_avoid")
        case .poorComfort: return L10n.text("keeping_outdoor_time_short_is")
        }
    }
    
    func iconName(for riskType: WeatherRiskType) -> String {
        switch riskType {
        case .heat: return "thermometer.sun.fill"
        case .uv: return "sun.max.fill"
        case .rain: return "cloud.rain.fill"
        case .wind: return "wind"
        case .humidity: return "humidity.fill"
        case .cold: return "snowflake"
        case .storm: return "cloud.bolt.rain.fill"
        case .poorComfort: return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Plan State

private extension HomeViewStateFactory {
    func makePlanState(from result: HomeRecommendationResult) -> HomePlanViewState {
        let recommendation = result.recommendation
        let isTomorrow = recommendation.isTomorrowsRecommendation
        
        var items: [HomePlanItem] = [
            HomePlanItem(
                id: "now",
                icon: decisionSymbolName(for: recommendation.outdoorDecision),
                title: isTomorrow ? L10n.text("tomorrow_label") : L10n.text("now"),
                timeText: recommendation.outdoorDecision.localizedTitle,
                detail: String(format: L10n.text("outdoor_score_detail_format"), recommendation.outdoorScore.rawValue),
                tone: assistantTone(for: recommendation.outdoorDecision),
                isPrimary: true
            )
        ]
        
        // Add official alert if present
        if let topAlert = result.alerts.sorted(by: { $0.severity > $1.severity }).first {
            items.append(HomePlanItem(
                id: "official-alert",
                icon: "exclamationmark.triangle.fill",
                title: L10n.text("safety_first"),
                timeText: L10n.text("active"),
                detail: topAlert.summary,
                tone: topAlert.severity >= .high ? .danger : .caution,
                isPrimary: topAlert.severity >= .high
            ))
        }
        
        // Add nowcast signal
        if let nowcast = makeNowcastSignal(from: result.minutePoints) {
            items.append(HomePlanItem(
                id: "nowcast",
                icon: nowcast.icon,
                title: nowcast.title,
                timeText: nowcast.subtitle,
                detail: nowcast.hint,
                tone: nowcast.tone,
                isPrimary: nowcast.tone == .danger
            ))
        }
        
        // Add best window
        if let bestWindow = recommendation.bestOutdoorWindow {
            items.append(HomePlanItem(
                id: "best-window",
                icon: "clock.fill",
                title: L10n.text("outdoor_plan"),
                timeText: bestWindow.shortDisplayText,
                detail: L10n.text("move_walks_errands_and_outdoor"),
                tone: .good,
                isPrimary: false
            ))
        }
        
        // Add avoid window
        if let avoidWindow = recommendation.avoidWindows.first {
            items.append(HomePlanItem(
                id: "avoid-window",
                icon: iconName(for: avoidWindow.risk.type),
                title: L10n.text("avoid"),
                timeText: avoidWindow.window.shortDisplayText,
                detail: avoidWindow.reason,
                tone: avoidWindow.severity >= .high ? .danger : .caution,
                isPrimary: avoidWindow.severity >= .high
            ))
        }
        
        // Add outfit
        if let outfitItem = recommendation.outfit.items.first {
            items.append(HomePlanItem(
                id: "outfit",
                icon: "tshirt.fill",
                title: L10n.text("prep"),
                timeText: outfitItem,
                detail: recommendation.outfit.warning ?? recommendation.outfit.title,
                tone: .info,
                isPrimary: false
            ))
        }
        
        // Add sunset
        if let sunset = result.dailyPoints.first?.sunset, sunset > dateProvider.now {
            items.append(HomePlanItem(
                id: "sunset",
                icon: "sunset.fill",
                title: L10n.text("sunset"),
                timeText: clockText(for: sunset),
                detail: L10n.text("use_this_as_a_natural"),
                tone: .info,
                isPrimary: false
            ))
        }
        
        return HomePlanViewState(
            title: isTomorrow ? L10n.text("tomorrows_plan") : L10n.text("todays_plan"),
            subtitle: L10n.text("a_short_action_plan_built"),
            items: Array(items.prefix(5))
        )
    }
    
    func makeNowcastSignal(from minutePoints: [MinuteWeatherPoint]) -> HomeAssistantSignal? {
        let nextHour = dateProvider.now.addingTimeInterval(60 * 60)
        let upcoming = minutePoints
            .filter { $0.date >= dateProvider.now && $0.date <= nextHour }
            .filter { $0.precipitationType.lowercased() != "none" || $0.precipitationChance >= 0.2 }
        
        guard let peak = upcoming.max(by: {
            let lhs = ($0.precipitationChance * 100) + ($0.precipitationIntensityMmPerHour * 12)
            let rhs = ($1.precipitationChance * 100) + ($1.precipitationIntensityMmPerHour * 12)
            return lhs < rhs
        }) else { return nil }
        
        guard peak.precipitationChance >= 0.35 || peak.precipitationIntensityMmPerHour >= 0.15 else {
            return nil
        }
        
        let minutes = max(1, Int(peak.date.timeIntervalSince(dateProvider.now) / 60))
        let chance = Int((peak.precipitationChance * 100).rounded())
        let intensityText = peak.precipitationIntensityMmPerHour >= 1.0
            ? L10n.text("rain_may_get_heavier")
            : L10n.text("light_rain_is_likely")
        
        return HomeAssistantSignal(
            id: "nowcast-rain",
            icon: "cloud.rain.fill",
            title: L10n.text("nowcast_rain"),
            subtitle: String(format: L10n.text("nowcast_subtitle_format"), chance, minutes),
            hint: String(format: L10n.text("nowcast_hint_format"), intensityText, minutes),
            tone: peak.precipitationChance >= 0.65 || peak.precipitationIntensityMmPerHour >= 1.0 ? .danger : .caution
        )
    }
    
    func decisionSymbolName(for decision: OutdoorDecision) -> String {
        switch decision {
        case .good: return "checkmark.seal.fill"
        case .moderate: return "sparkles"
        case .risky: return "exclamationmark.triangle.fill"
        case .avoid: return "xmark.octagon.fill"
        }
    }
    
    func assistantTone(for decision: OutdoorDecision) -> HomeAssistantTone {
        switch decision {
        case .good: return .good
        case .moderate: return .info
        case .risky: return .caution
        case .avoid: return .danger
        }
    }
}

// MARK: - Weather State

private extension HomeViewStateFactory {
    func makeCurrentWeatherState(
        from current: CurrentWeatherPoint,
        dailyPoints: [DailyWeatherPoint],
        unitSystem: UnitSystem
    ) -> HomeCurrentWeatherViewState {
        let humidityText = current.humidity.map { String(format: "%.0f%%", $0 * 100) } ?? "–"
        
        let windText: String
        if let wind = current.windSpeedKph {
            switch unitSystem {
            case .metric: windText = String(format: "%.0f km/h", wind)
            case .imperial: windText = String(format: "%.0f mph", wind / 1.60934)
            }
        } else {
            windText = "–"
        }
        
        let uvText = current.uvIndex.map { String($0) } ?? "–"
        
        let today = dailyPoints.first
        let highText = today.map { formatTemperature($0.highTemperatureCelsius, unitSystem: unitSystem) } ?? "–"
        let lowText = today.map { formatTemperature($0.lowTemperatureCelsius, unitSystem: unitSystem) } ?? "–"
        
        let sunriseSunset = makeSunriseSunsetText(from: dailyPoints)
        
        return HomeCurrentWeatherViewState(
            temperatureText: formatTemperature(current.temperatureCelsius, unitSystem: unitSystem),
            feelsLikeText: L10n.text("weather_feels_like") + " " + formatTemperature(current.apparentTemperatureCelsius, unitSystem: unitSystem),
            conditionText: conditionText(for: current.conditionCode),
            symbolName: current.symbolName ?? symbolName(for: current.conditionCode, isDaylight: current.isDaylight),
            humidityText: humidityText,
            windText: windText,
            uvIndexText: uvText,
            highTempText: highText,
            lowTempText: lowText,
            sunriseText: sunriseSunset?.0,
            sunsetText: sunriseSunset?.1
        )
    }
    
    func makeSunriseSunsetText(from dailyPoints: [DailyWeatherPoint]) -> (String, String)? {
        guard let today = dailyPoints.first,
              let sunrise = today.sunrise,
              let sunset = today.sunset else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return (formatter.string(from: sunrise), formatter.string(from: sunset))
    }
    
    func conditionText(for conditionCode: String?) -> String {
        let condition = conditionCode?.lowercased() ?? ""
        
        switch true {
        case condition.contains("thunder"), condition.contains("storm"):
            return L10n.text("weather_storm")
        case condition.contains("rain"), condition.contains("drizzle"):
            return L10n.text("weather_rain")
        case condition.contains("snow"), condition.contains("sleet"):
            return L10n.text("weather_snow")
        case condition.contains("cloud"):
            return L10n.text("weather_cloudy")
        case condition.contains("fog"), condition.contains("haze"):
            return L10n.text("weather_foggy")
        case condition.contains("clear"), condition.contains("sun"):
            return L10n.text("weather_clear")
        default:
            return L10n.text("weather_current")
        }
    }
    
    func symbolName(for conditionCode: String?, isDaylight: Bool?) -> String {
        let condition = conditionCode?.lowercased() ?? ""
        
        switch true {
        case condition.contains("thunder"), condition.contains("storm"):
            return "cloud.bolt.rain.fill"
        case condition.contains("rain"), condition.contains("drizzle"):
            return "cloud.rain.fill"
        case condition.contains("snow"), condition.contains("sleet"):
            return "cloud.snow.fill"
        case condition.contains("cloud"):
            return isDaylight == false ? "cloud.moon.fill" : "cloud.sun.fill"
        case condition.contains("fog"), condition.contains("haze"):
            return "cloud.fog.fill"
        default:
            return isDaylight == false ? "moon.stars.fill" : "sun.max.fill"
        }
    }
}

// MARK: - Forecasts

private extension HomeViewStateFactory {
    func makeDailyForecasts(from dailyPoints: [DailyWeatherPoint], unitSystem: UnitSystem) -> [DailyForecastItem] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: dateProvider.now)
        
        return dailyPoints.map { point in
            let dayStart = calendar.startOfDay(for: point.date)
            let isToday = dayStart == todayStart
            
            let dayName: String
            if isToday {
                dayName = L10n.text("today_label")
            } else {
                // Get localized weekday name using weekday symbol
                let weekdayIndex = calendar.component(.weekday, from: point.date) - 1
                let weekdays = [
                    L10n.text("sunday"),
                    L10n.text("monday"),
                    L10n.text("tuesday"),
                    L10n.text("wednesday"),
                    L10n.text("thursday"),
                    L10n.text("friday"),
                    L10n.text("saturday")
                ]
                dayName = weekdays[weekdayIndex]
            }
            
            let score = weeklyScore(high: point.highTemperatureCelsius, low: point.lowTemperatureCelsius, precipitationChance: point.precipitationChance)
            let decision = OutdoorDecision(score: WeatherScore(rawValue: score))
            
            return DailyForecastItem(
                dayName: dayName,
                date: point.date,
                highTemp: convertTemperature(point.highTemperatureCelsius, unitSystem: unitSystem),
                lowTemp: convertTemperature(point.lowTemperatureCelsius, unitSystem: unitSystem),
                conditionSymbol: point.symbolName ?? symbolName(for: point.conditionCode, isDaylight: true),
                outdoorScore: score,
                outdoorDecision: decision,
                isToday: isToday,
                precipitationChance: point.precipitationChance ?? 0
            )
        }
    }
    
    func makeHourlyScores(
        from hourlyPoints: [HourlyWeatherPoint],
        profile: UserComfortProfile,
        unitSystem: UnitSystem
    ) -> [HourlyScoreItem] {
        hourlyPoints
            .filter { $0.date >= dateProvider.now.addingTimeInterval(-15 * 60) }
            .sorted { $0.date < $1.date }
            .prefix(24)
            .map { point in
                let score = activityWindowScoringEngine.score(
                    hour: point,
                    activity: .goingOutside,
                    profile: profile,
                    calendar: .current
                )
                
                return HourlyScoreItem(
                    date: point.date,
                    hour: Calendar.current.component(.hour, from: point.date),
                    score: score.rawValue,
                    symbolName: point.symbolName ?? symbolName(for: point.conditionCode, isDaylight: point.isDaylight),
                    temperatureText: formatTemperature(point.temperatureCelsius, unitSystem: unitSystem),
                    precipitationChance: point.precipitationChance ?? 0
                )
            }
    }
    
    func weeklyScore(high: Double, low: Double, precipitationChance: Double?) -> Int {
        var score = 100.0
        score -= abs(high - 24) * 1.8
        score -= abs(15 - low) * 1.8
        if let precip = precipitationChance {
            score -= precip * 0.55
        }
        return Int(max(0, min(100, score)))
    }
}

// MARK: - Formatting

private extension HomeViewStateFactory {
    func formatTemperature(_ celsius: Double, unitSystem: UnitSystem) -> String {
        let value: Double
        let suffix: String
        
        switch unitSystem {
        case .metric:
            value = celsius
            suffix = "°"
        case .imperial:
            value = (celsius * 9 / 5) + 32
            suffix = "°F"
        }
        
        return value.formatted(.number.precision(.fractionLength(0))) + suffix
    }
    
    func convertTemperature(_ celsius: Double, unitSystem: UnitSystem) -> Double {
        switch unitSystem {
        case .metric: return celsius
        case .imperial: return (celsius * 9 / 5) + 32
        }
    }
    
    func lastUpdatedText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = .current
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: dateProvider.now)
    }
    
    func clockText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
