import Combine
import Foundation
import WidgetKit

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<HomeViewState> = .idle
    @Published private(set) var selectedLocationName: String = L10n.text( "home_current_location")

    private let loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase
    private let scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase
    private let preferencesRepository: PreferencesRepository
    private let widgetRepository: WidgetRepository
    private let dateProvider: DateProvider
    private var didLoad = false

    private var selectedLocation: SavedLocation?
    private var selectedLocationID: String = "current-location"

    init(
        loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase,
        scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase,
        preferencesRepository: PreferencesRepository,
        widgetRepository: WidgetRepository,
        dateProvider: DateProvider = SystemDateProvider(),
        selectedLocationName: String = L10n.text( "home_current_location")
    ) {
        self.loadHomeRecommendationUseCase = loadHomeRecommendationUseCase
        self.scheduleSmartNotificationsUseCase = scheduleSmartNotificationsUseCase
        self.preferencesRepository = preferencesRepository
        self.widgetRepository = widgetRepository
        self.dateProvider = dateProvider
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

    func refresh() async {
        await load(forceRefresh: true)
    }

    func changeLocation(to location: SavedLocation) async {
        selectedLocation = location
        selectedLocationID = location.id
        selectedLocationName = location.name

        var updatedProfile = (try? await preferencesRepository.loadProfile()) ?? .default
        updatedProfile.selectedLocationID = location.id
        _ = try? await preferencesRepository.saveProfile(updatedProfile)

        didLoad = false
        await load(forceRefresh: true)
    }

    private func load(forceRefresh: Bool) async {
        if case .loaded = state {
            state = .loading
        } else {
            state = .loading
        }

        do {
            let targetLocation: LocationCoordinate?
            if let selectedLocation, selectedLocation.id != "current-location" {
                targetLocation = LocationCoordinate(latitude: selectedLocation.latitude, longitude: selectedLocation.longitude)
            } else {
                targetLocation = nil
            }

            let result = try await loadHomeRecommendationUseCase.execute(forceRefresh: forceRefresh, targetLocation: targetLocation)
            let profile = try await preferencesRepository.loadProfile()

            state = .loaded(
                HomeViewState(
                    recommendation: result.recommendation,
                    currentWeather: currentWeatherViewState(
                        from: result.currentWeather,
                        unitSystem: profile.unitSystem
                    ),
                    dailyForecasts: makeDailyForecastItems(from: result.dailyPoints, unitSystem: profile.unitSystem),
                    lastUpdatedText: lastUpdatedText(for: result.weatherFetchedAt),
                    isUsingCachedWeather: result.isUsingCachedWeather,
                    warningMessage: result.warningMessage,
                    attribution: result.attribution
                )
            )

            _ = try? await scheduleSmartNotificationsUseCase.execute(
                recommendation: result.recommendation,
                profile: profile
            )

            try? widgetRepository.save(recommendation: result.recommendation)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            state = .failed(message(for: error))
        }
    }

    private func currentWeatherViewState(
        from current: CurrentWeatherPoint,
        unitSystem: UnitSystem
    ) -> HomeCurrentWeatherViewState {
        HomeCurrentWeatherViewState(
            temperatureText: temperatureText(current.temperatureCelsius, unitSystem: unitSystem),
            feelsLikeText: L10n.text( "weather_feels_like") + " " + temperatureText(
                current.apparentTemperatureCelsius,
                unitSystem: unitSystem
            ),
            conditionText: conditionText(for: current.conditionCode),
            symbolName: symbolName(for: current.conditionCode, isDaylight: current.isDaylight)
        )
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

    private func makeDailyForecastItems(from dailyPoints: [DailyWeatherPoint], unitSystem: UnitSystem) -> [DailyForecastItem] {
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

            let score = weeklyScore(high: point.highTemperatureCelsius, low: point.lowTemperatureCelsius, precipitationChance: point.precipitationChance)
            let decision = OutdoorDecision(score: WeatherScore(rawValue: score))

            let highTemp = convertTemperature(point.highTemperatureCelsius, unitSystem: unitSystem)
            let lowTemp = convertTemperature(point.lowTemperatureCelsius, unitSystem: unitSystem)

            return DailyForecastItem(
                dayName: dayName,
                date: point.date,
                highTemp: highTemp,
                lowTemp: lowTemp,
                conditionSymbol: symbolName(for: point.conditionCode, isDaylight: true),
                outdoorScore: score,
                outdoorDecision: decision,
                isToday: isToday
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
}
