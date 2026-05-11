import Combine
import CoreLocation
import Foundation
import os.log

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<HomeViewState> = .idle
    @Published private(set) var selectedLocationName: String = L10n.text( "home_current_location")

    private let loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase
    private let scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase
    private let preferencesRepository: PreferencesRepository
    private let dateProvider: DateProvider
    private let activityWindowScoringEngine: ActivityWindowScoringEngine
    private var didLoad = false

    private var selectedLocation: SavedLocation?
    private var selectedLocationID: String = "current-location"
    private let geocoder = CLGeocoder()

    init(
        loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase,
        scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase,
        preferencesRepository: PreferencesRepository,
        dateProvider: DateProvider = SystemDateProvider(),
        activityWindowScoringEngine: ActivityWindowScoringEngine = DefaultActivityWindowScoringEngine(),
        selectedLocationName: String = L10n.text( "home_current_location")
    ) {
        self.loadHomeRecommendationUseCase = loadHomeRecommendationUseCase
        self.scheduleSmartNotificationsUseCase = scheduleSmartNotificationsUseCase
        self.preferencesRepository = preferencesRepository
        self.dateProvider = dateProvider
        self.activityWindowScoringEngine = activityWindowScoringEngine
        self.selectedLocationName = selectedLocationName
    }

    func onAppear() {
        guard didLoad == false else {
            return
        }

        didLoad = true
        Task {
            await load(forceRefresh: false)
        }
    }

    func reloadForLanguageChange() async {
        didLoad = false
        await load(forceRefresh: false)
    }

    func refresh() async {
        await load(forceRefresh: true)
    }

    func changeLocation(to location: SavedLocation) async {
        selectedLocation = location
        selectedLocationID = location.id
        selectedLocationName = location.name

        do {
            var updatedProfile = try await preferencesRepository.loadProfile()
            updatedProfile.selectedLocationID = location.id
            try await preferencesRepository.saveProfile(updatedProfile)
        } catch {
            AppLogger.app.error("Failed to update location preference: \(error.localizedDescription)")
        }

        didLoad = false
        await load(forceRefresh: true)
    }

    private func load(forceRefresh: Bool) async {
        state = .loading

        do {
            let targetLocation: LocationCoordinate?
            if let selectedLocation,
               selectedLocation.id != "current-location" {
                targetLocation = LocationCoordinate(
                    latitude: selectedLocation.latitude,
                    longitude: selectedLocation.longitude
                )
            } else {
                targetLocation = nil
            }

            let result = try await loadHomeRecommendationUseCase
                .execute(forceRefresh: forceRefresh, targetLocation: targetLocation)
            let profile = try await preferencesRepository.loadProfile()

state = .loaded(
                    HomeViewState(
                        recommendation: result.recommendation,
                        assistant: makeAssistantState(from: result),
                        plan: makePlanState(from: result),
                        currentWeather: currentWeatherViewState(
                            from: result.currentWeather,
                            unitSystem: .current,
                            dailyPoints: result.dailyPoints
                        ),
                        dailyForecasts: makeDailyForecastItems(from: result.dailyPoints, unitSystem: .current),
                        hourlyScores: makeHourlyScores(
                            from: result.hourlyPoints,
                            profile: profile,
                            unitSystem: .current
                        ),
                        lastUpdatedText: lastUpdatedText(for: result.weatherFetchedAt),
                        isUsingCachedWeather: result.isUsingCachedWeather,
                        warningMessage: result.warningMessage,
                        attribution: result.attribution
                    )
                )

            if selectedLocation == nil || selectedLocation?.id == "current-location",
               let location = result.usedLocation {
                resolveLocationName(for: location)
            }

            do {
                _ = try await scheduleSmartNotificationsUseCase.execute(
                    recommendation: result.recommendation,
                    profile: profile
                )
            } catch {
                AppLogger.notifications.error("Failed to schedule notifications: \(error.localizedDescription)")
            }


        } catch {
            state = .failed(message(for: error))
        }
    }

    private func makeAssistantState(from result: HomeRecommendationResult) -> HomeAssistantViewState {
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

        let headline: String
        let symbolName: String
        let tone: HomeAssistantTone

        if criticalAlert != nil {
            headline = L10n.text("official_weather_alert")
            symbolName = "exclamationmark.triangle.fill"
            tone = .danger
        } else if let topRisk = recommendation.risks.first(where: { $0.severity >= .high }) {
            headline = L10n.text("adjust_the_plan_for_safety")
            symbolName = iconName(for: topRisk.type)
            tone = .danger
        } else {
            headline = headlineText(for: recommendation.outdoorDecision, isTomorrow: recommendation.isTomorrowsRecommendation)
            symbolName = decisionSymbolName(for: recommendation.outdoorDecision)
            tone = assistantTone(for: recommendation.outdoorDecision)
        }

        return HomeAssistantViewState(
            headline: headline,
            symbolName: symbolName,
            tone: tone,
            criticalAlert: criticalAlert
        )
    }

    private func makePlanState(from result: HomeRecommendationResult) -> HomePlanViewState {
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

        if let topAlert = result.alerts.sorted(by: { $0.severity > $1.severity }).first {
            items.append(
                HomePlanItem(
                    id: "official-alert",
                    icon: "exclamationmark.triangle.fill",
                    title: L10n.text("safety_first"),
                    timeText: L10n.text("active"),
                    detail: topAlert.summary,
                    tone: topAlert.severity >= .high ? .danger : .caution,
                    isPrimary: topAlert.severity >= .high
                )
            )
        }

        if let nowcast = makeNowcastSignal(from: result.minutePoints) {
            items.append(
                HomePlanItem(
                    id: "nowcast",
                    icon: nowcast.icon,
                    title: nowcast.title,
                    timeText: nowcast.subtitle,
                    detail: nowcast.hint,
                    tone: nowcast.tone,
                    isPrimary: nowcast.tone == .danger
                )
            )
        }

        if let bestWindow = recommendation.bestOutdoorWindow {
            items.append(
                HomePlanItem(
                    id: "best-window",
                    icon: "clock.fill",
                    title: L10n.text("outdoor_plan"),
                    timeText: bestWindow.shortDisplayText,
                    detail: L10n.text("move_walks_errands_and_outdoor"),
                    tone: .good,
                    isPrimary: false
                )
            )
        }

        if let avoidWindow = recommendation.avoidWindows.first {
            items.append(
                HomePlanItem(
                    id: "avoid-window",
                    icon: iconName(for: avoidWindow.risk.type),
                    title: L10n.text("avoid"),
                    timeText: avoidWindow.window.shortDisplayText,
                    detail: avoidWindow.reason,
                    tone: avoidWindow.severity >= .high ? .danger : .caution,
                    isPrimary: avoidWindow.severity >= .high
                )
            )
        }

        if let outfitItem = recommendation.outfit.items.first {
            items.append(
                HomePlanItem(
                    id: "outfit",
                    icon: "tshirt.fill",
                    title: L10n.text("prep"),
                    timeText: outfitItem,
                    detail: recommendation.outfit.warning ?? recommendation.outfit.title,
                    tone: .info,
                    isPrimary: false
                )
            )
        }

        if let sunset = result.dailyPoints.first?.sunset,
           sunset > dateProvider.now {
            items.append(
                HomePlanItem(
                    id: "sunset",
                    icon: "sunset.fill",
                    title: L10n.text("sunset"),
                    timeText: clockText(for: sunset),
                    detail: L10n.text("use_this_as_a_natural"),
                    tone: .info,
                    isPrimary: false
                )
            )
        }

        return HomePlanViewState(
            title: isTomorrow ? L10n.text("tomorrows_plan") : L10n.text("todays_plan"),
            subtitle: L10n.text("a_short_action_plan_built"),
            items: Array(items.prefix(3))
        )
    }

    private func makeNowcastSignal(from minutePoints: [MinuteWeatherPoint]) -> HomeAssistantSignal? {
        let nextHour = dateProvider.now.addingTimeInterval(60 * 60)
        let upcoming = minutePoints
            .filter { $0.date >= dateProvider.now && $0.date <= nextHour }
            .filter { $0.precipitationType.lowercased() != "none" || $0.precipitationChance >= 0.2 }

        guard let peak = upcoming.max(by: {
            let lhs = ($0.precipitationChance * 100) + ($0.precipitationIntensityMmPerHour * 12)
            let rhs = ($1.precipitationChance * 100) + ($1.precipitationIntensityMmPerHour * 12)
            return lhs < rhs
        }) else {
            return nil
        }

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

    private func headlineText(for decision: OutdoorDecision, isTomorrow: Bool) -> String {
        let prefix = isTomorrow ? L10n.text("tomorrow_prefix") + " " : ""
        switch decision {
        case .good:
            return prefix + L10n.text("clear_outdoor_day")
        case .moderate:
            return prefix + L10n.text("good_to_go_with_light")
        case .risky:
            return prefix + L10n.text("plan_carefully")
        case .avoid:
            return prefix + L10n.text("better_to_postpone_outdoor_plans")
        }
    }

    private func assistantTone(for decision: OutdoorDecision) -> HomeAssistantTone {
        switch decision {
        case .good:
            return .good
        case .moderate:
            return .info
        case .risky:
            return .caution
        case .avoid:
            return .danger
        }
    }

    private func decisionSymbolName(for decision: OutdoorDecision) -> String {
        switch decision {
        case .good:
            return "checkmark.seal.fill"
        case .moderate:
            return "sparkles"
        case .risky:
            return "exclamationmark.triangle.fill"
        case .avoid:
            return "xmark.octagon.fill"
        }
    }

    private func iconName(for riskType: WeatherRiskType) -> String {
        switch riskType {
        case .heat:
            return "thermometer.sun.fill"
        case .uv:
            return "sun.max.fill"
        case .rain:
            return "cloud.rain.fill"
        case .wind:
            return "wind"
        case .humidity:
            return "humidity.fill"
        case .cold:
            return "snowflake"
        case .storm:
            return "cloud.bolt.rain.fill"
        case .poorComfort:
            return "exclamationmark.circle.fill"
        }
    }

    private func currentWeatherViewState(
        from current: CurrentWeatherPoint,
        unitSystem: UnitSystem,
        dailyPoints: [DailyWeatherPoint]
    ) -> HomeCurrentWeatherViewState {
        let humidityText: String
        if let h = current.humidity {
            humidityText = String(format: "%.0f%%", h * 100)
        } else {
            humidityText = "–"
        }

        let windText: String
        if let w = current.windSpeedKph {
            switch unitSystem {
            case .metric:   windText = String(format: "%.0f km/h", w)
            case .imperial: windText = String(format: "%.0f mph",  w / 1.60934)
            }
        } else {
            windText = "–"
        }

        let uvText = current.uvIndex.map { String($0) } ?? "–"

        let today = dailyPoints.first
        let highText = today.map { temperatureText($0.highTemperatureCelsius, unitSystem: unitSystem) } ?? "–"
        let lowText  = today.map { temperatureText($0.lowTemperatureCelsius,  unitSystem: unitSystem) } ?? "–"

        let sunriseSunset = makeSunriseSunsetText(from: dailyPoints)

        return HomeCurrentWeatherViewState(
            temperatureText: temperatureText(current.temperatureCelsius, unitSystem: unitSystem),
            feelsLikeText: L10n.text("weather_feels_like") + " " + temperatureText(
                current.apparentTemperatureCelsius,
                unitSystem: unitSystem
            ),
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

    private func makeSunriseSunsetText(from dailyPoints: [DailyWeatherPoint]) -> (String, String)? {
        guard let today = dailyPoints.first,
              let sunrise = today.sunrise,
              let sunset = today.sunset else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        return (formatter.string(from: sunrise), formatter.string(from: sunset))
    }

    private func temperatureText(_ celsius: Double, unitSystem: UnitSystem) -> String {
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

    private func conditionText(for conditionCode: String?) -> String {
        let condition = conditionCode?.lowercased() ?? ""

        if condition.contains("thunder") || condition.contains("storm") {
            return L10n.text( "weather_storm")
        }

        if condition.contains("rain") || condition.contains("drizzle") {
            return L10n.text( "weather_rain")
        }

        if condition.contains("snow") || condition.contains("sleet") {
            return L10n.text( "weather_snow")
        }

        if condition.contains("cloud") {
            return L10n.text( "weather_cloudy")
        }

        if condition.contains("fog") || condition.contains("haze") {
            return L10n.text( "weather_foggy")
        }

        if condition.contains("clear") || condition.contains("sun") {
            return L10n.text( "weather_clear")
        }

        return L10n.text( "weather_current")
    }

    private func symbolName(for conditionCode: String?, isDaylight: Bool?) -> String {
        let condition = conditionCode?.lowercased() ?? ""

        if condition.contains("thunder") || condition.contains("storm") {
            return "cloud.bolt.rain.fill"
        }

        if condition.contains("rain") || condition.contains("drizzle") {
            return "cloud.rain.fill"
        }

        if condition.contains("snow") || condition.contains("sleet") {
            return "cloud.snow.fill"
        }

        if condition.contains("cloud") {
            return isDaylight == false ? "cloud.moon.fill" : "cloud.sun.fill"
        }

        if condition.contains("fog") || condition.contains("haze") {
            return "cloud.fog.fill"
        }

        return isDaylight == false ? "moon.stars.fill" : "sun.max.fill"
    }

    private func lastUpdatedText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = .current
        formatter.unitsStyle = .short

        return formatter.localizedString(for: date, relativeTo: dateProvider.now)
    }

    private func clockText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func makeDailyForecastItems(
        from dailyPoints: [DailyWeatherPoint],
        unitSystem: UnitSystem
    ) -> [DailyForecastItem] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: dateProvider.now)

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE"

        return dailyPoints.map { point in
            let dayStart = calendar.startOfDay(for: point.date)
            let isToday = dayStart == todayStart

            let dayName: String
            if isToday {
                dayName = L10n.text( "today_label")
            } else {
                dayName = formatter.string(from: point.date).capitalized
            }

            let score = weeklyScore(
                high: point.highTemperatureCelsius,
                low: point.lowTemperatureCelsius,
                precipitationChance: point.precipitationChance
            )
            let decision = OutdoorDecision(score: WeatherScore(rawValue: score))

            let highTemp = convertTemperature(point.highTemperatureCelsius, unitSystem: unitSystem)
            let lowTemp = convertTemperature(point.lowTemperatureCelsius, unitSystem: unitSystem)

            let conditionSymbol = point.symbolName ?? symbolName(for: point.conditionCode, isDaylight: true)

            return DailyForecastItem(
                dayName: dayName,
                date: point.date,
                highTemp: highTemp,
                lowTemp: lowTemp,
                conditionSymbol: conditionSymbol,
                outdoorScore: score,
                outdoorDecision: decision,
                isToday: isToday,
                precipitationChance: point.precipitationChance ?? 0
            )
        }
    }

    private func weeklyScore(high: Double, low: Double, precipitationChance: Double?) -> Int {
        var score = 100.0
        score -= abs(high - 24) * 1.8
        score -= abs(15 - low) * 1.8
        if let precip = precipitationChance {
            score -= precip * 0.55
        }
        return Int(max(0, min(100, score)))
    }

    private func makeHourlyScores(
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
                    symbolName: point.symbolName ?? symbolName(
                        for: point.conditionCode,
                        isDaylight: point.isDaylight
                    ),
                    temperatureText: temperatureText(point.temperatureCelsius, unitSystem: unitSystem),
                    precipitationChance: point.precipitationChance ?? 0
                )
            }
    }

    private func convertTemperature(_ celsius: Double, unitSystem: UnitSystem) -> Double {
        switch unitSystem {
        case .metric:
            celsius
        case .imperial:
            (celsius * 9 / 5) + 32
        }
    }

    private func message(for error: any Error) -> String {
        if let appError = error as? AppError {
            return appError.userMessage
        }

        return AppError.unknown.userMessage
    }

private func resolveLocationName(for location: LocationCoordinate) {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(clLocation) { [weak self] placemarks, _ in
            guard let self, let placemark = placemarks?.first else { return }

            let city = placemark.locality
                ?? placemark.administrativeArea
                ?? placemark.country

            let countryCode = placemark.isoCountryCode

            let name: String
            if let city {
                name = city
            } else {
                name = city ?? L10n.text("home_current_location")
            }

            Task { @MainActor in
                self.selectedLocationName = name
            }
        }
    }

}
