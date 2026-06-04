import Foundation

/// Factory for creating HomeViewState from domain models.
///
/// Extracts all presentation logic from HomeViewModel, following the
/// Factory pattern for testability and separation of concerns.
@MainActor
final class HomeViewStateFactory {
    private let dateProvider: DateProvider
    let activityWindowScoringEngine: ActivityWindowScoringEngine
    private let mapper: WeatherPresentationMapper
    
    init(
        dateProvider: DateProvider = SystemDateProvider(),
        activityWindowScoringEngine: ActivityWindowScoringEngine = DefaultActivityWindowScoringEngine(),
        mapper: WeatherPresentationMapper = WeatherPresentationMapper()
    ) {
        self.dateProvider = dateProvider
        self.activityWindowScoringEngine = activityWindowScoringEngine
        self.mapper = mapper
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
            let localizedText = L10n.text("official_weather_alert")
            let adjustedText = isTomorrow ? localizedText.lowercasedFirst : localizedText
            return (
                prefix + adjustedText,
                "exclamationmark.triangle.fill",
                .danger
            )
        }
        
        if let risk = topRisk {
            let localizedText = L10n.text("adjust_the_plan_for_safety")
            let adjustedText = isTomorrow ? localizedText.lowercasedFirst : localizedText
            return (
                prefix + adjustedText,
                iconName(for: risk.type),
                .danger
            )
        }
        
        let (headline, symbol, tone) = decisionPresentation(for: recommendation.outdoorDecision, isTomorrow: isTomorrow)
        return (headline, symbol, tone)
    }
    
    func decisionPresentation(for decision: OutdoorDecision, isTomorrow: Bool) -> (String, String, HomeAssistantTone) {
        let prefix = isTomorrow ? L10n.text("tomorrow_prefix") + " " : ""
        
        let rawHeadline: String
        switch decision {
        case .good:
            rawHeadline = L10n.text("clear_outdoor_day")
        case .moderate:
            rawHeadline = L10n.text("good_to_go_with_light")
        case .risky:
            rawHeadline = L10n.text("plan_carefully")
        case .avoid:
            rawHeadline = L10n.text("better_to_postpone_outdoor_plans")
        }
        
        let headline = isTomorrow ? rawHeadline.lowercasedFirst : rawHeadline
        
        switch decision {
        case .good:
            return (prefix + headline, "checkmark.seal.fill", .good)
        case .moderate:
            return (prefix + headline, "sparkles", .info)
        case .risky:
            return (prefix + headline, "exclamationmark.triangle.fill", .caution)
        case .avoid:
            return (prefix + headline, "xmark.octagon.fill", .danger)
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
        case .airQuality: return L10n.text("action_air_quality_advice")
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
        case .airQuality: return "lungs.fill"
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
        let highText = today.map { mapper.temperatureText($0.highTemperatureCelsius, unitSystem: unitSystem) } ?? "–"
        let lowText = today.map { mapper.temperatureText($0.lowTemperatureCelsius, unitSystem: unitSystem) } ?? "–"
        
        let sunriseSunset = makeSunriseSunsetText(from: dailyPoints)
        
        return HomeCurrentWeatherViewState(
            temperatureText: mapper.temperatureText(current.temperatureCelsius, unitSystem: unitSystem),
            feelsLikeText: L10n.text("weather_feels_like") + " " + mapper.temperatureText(current.apparentTemperatureCelsius, unitSystem: unitSystem),
            conditionText: mapper.conditionText(for: current.conditionCode),
            symbolName: current.symbolName ?? mapper.symbolName(for: current.conditionCode, isDaylight: current.isDaylight),
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
            
            let score = mapper.dailyScore(highCelsius: point.highTemperatureCelsius, lowCelsius: point.lowTemperatureCelsius, precipitationChance: point.precipitationChance)
            let decision = OutdoorDecision(score: WeatherScore(rawValue: score))
            
            return DailyForecastItem(
                dayName: dayName,
                date: point.date,
                highTemp: mapper.temperatureValue(point.highTemperatureCelsius, unitSystem: unitSystem),
                lowTemp: mapper.temperatureValue(point.lowTemperatureCelsius, unitSystem: unitSystem),
                conditionSymbol: point.symbolName ?? mapper.symbolName(for: point.conditionCode, isDaylight: true),
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
                    symbolName: point.symbolName ?? mapper.symbolName(for: point.conditionCode, isDaylight: point.isDaylight),
                    temperatureText: mapper.temperatureText(point.temperatureCelsius, unitSystem: unitSystem),
                    precipitationChance: point.precipitationChance ?? 0
                )
            }
    }
    

}


// MARK: - Formatting

private extension HomeViewStateFactory {
    func lastUpdatedText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = .current
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: dateProvider.now)
    }
}

// MARK: - String Helpers

fileprivate extension String {
    var lowercasedFirst: String {
        guard !isEmpty else { return self }
        return prefix(1).lowercased() + dropFirst()
    }
}
