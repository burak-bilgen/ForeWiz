import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<HomeViewState> = .idle

    private let loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase
    private let scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase
    private let preferencesRepository: PreferencesRepository
    private let dateProvider: DateProvider
    private var didLoad = false

    init(
        loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase,
        scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase,
        preferencesRepository: PreferencesRepository,
        dateProvider: DateProvider
    ) {
        self.loadHomeRecommendationUseCase = loadHomeRecommendationUseCase
        self.scheduleSmartNotificationsUseCase = scheduleSmartNotificationsUseCase
        self.preferencesRepository = preferencesRepository
        self.dateProvider = dateProvider
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

    private func load(forceRefresh: Bool) async {
        if case .loaded = state {
            state = .loading
        } else {
            state = .loading
        }

        do {
            let result = try await loadHomeRecommendationUseCase.execute(forceRefresh: forceRefresh)
            let profile = try await preferencesRepository.loadProfile()

            state = .loaded(
                HomeViewState(
                    recommendation: result.recommendation,
                    currentWeather: currentWeatherViewState(
                        from: result.currentWeather,
                        unitSystem: profile.unitSystem
                    ),
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
            feelsLikeText: "Hissedilen: " + temperatureText(
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
            return "Fırtına"
        }

        if condition.contains("rain") || condition.contains("drizzle") {
            return "Yağmur"
        }

        if condition.contains("snow") || condition.contains("sleet") {
            return "Kar"
        }

        if condition.contains("cloud") {
            return "Bulutlu"
        }

        if condition.contains("fog") || condition.contains("haze") {
            return "Puslu"
        }

        if condition.contains("clear") || condition.contains("sun") {
            return "Açık"
        }

        return "Güncel hava"
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
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .short

        return formatter.localizedString(for: date, relativeTo: dateProvider.now)
    }

    private func message(for error: any Error) -> String {
        if let appError = error as? AppError {
            return appError.userMessage
        }

        return AppError.unknown.userMessage
    }
}
