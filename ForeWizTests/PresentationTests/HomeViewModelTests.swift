import Foundation
import Testing
@testable import ForeWiz

@MainActor
struct HomeViewModelTests {
    @Test func initialStateIsIdle() {
        let viewModel = makeViewModel()

        #expect(viewModel.state == LoadableState<HomeViewState>.idle)
    }

    @Test func refreshLoadsWeatherState() async {
        let viewModel = makeViewModel()

        await viewModel.refresh()

        guard case .loaded(let state) = viewModel.state else {
            #expect(Bool(false), "Expected loaded state")
            return
        }

        #expect(state.currentWeather.temperatureText.isEmpty == false)
        #expect(state.hourlyScores.isEmpty == false)
        #expect(state.dailyForecasts.isEmpty == false)
    }

    @Test func errorStateShowsMessage() async {
        let viewModel = makeViewModel(loadError: AppError.weatherUnavailable)

        await viewModel.refresh()

        guard case .failed(let message) = viewModel.state else {
            #expect(Bool(false), "Expected failed state")
            return
        }

        #expect(message.isEmpty == false)
    }

    @Test func onAppearTriggersSingleLoad() async {
        let loadUseCase = MockLoadHomeRecommendationUseCase(result: .sample)
        let viewModel = makeViewModel(loadUseCase: loadUseCase)

        viewModel.onAppear()
        viewModel.onAppear()
        try? await Task.sleep(nanoseconds: 150_000_000)

        #expect(loadUseCase.executeCount == 1)
        #expect(loadUseCase.lastForceRefresh == false)
    }

    private func makeViewModel(
        loadUseCase: MockLoadHomeRecommendationUseCase? = nil,
        loadError: Error? = nil
    ) -> HomeViewModel {
        HomeViewModel(
            loadHomeRecommendationUseCase: loadUseCase ?? MockLoadHomeRecommendationUseCase(
                result: .sample,
                error: loadError
            ),
            scheduleSmartNotificationsUseCase: MockScheduleSmartNotificationsUseCase(),
            preferencesRepository: MockPreferencesRepository()
        )
    }
}

private final class MockLoadHomeRecommendationUseCase: LoadHomeRecommendationUseCase {
    private(set) var executeCount = 0
    private(set) var lastForceRefresh: Bool?
    private let result: HomeRecommendationResult
    private let error: Error?

    init(result: HomeRecommendationResult, error: Error? = nil) {
        self.result = result
        self.error = error
    }

    func execute(forceRefresh: Bool, targetLocation: LocationCoordinate?) async throws -> HomeRecommendationResult {
        executeCount += 1
        lastForceRefresh = forceRefresh

        if let error {
            throw error
        }

        return result
    }
}

private final class MockScheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase {
    func execute(recommendation: DailyRecommendation, profile: UserComfortProfile) async throws -> [NotificationPlan] {
        []
    }
}

private final class MockPreferencesRepository: PreferencesRepository {
    private var profile: UserComfortProfile = .default
    private var onboardingCompleted = true

    func loadProfile() async throws -> UserComfortProfile {
        profile
    }

    func saveProfile(_ profile: UserComfortProfile) async throws {
        self.profile = profile
    }

    func isOnboardingCompleted() async throws -> Bool {
        onboardingCompleted
    }

    func setOnboardingCompleted(_ completed: Bool) async throws {
        onboardingCompleted = completed
    }
}

private extension HomeRecommendationResult {
    static var sample: HomeRecommendationResult {
        let calendar = Calendar.current
        let now = Date()
        let hourly = (0..<6).compactMap { offset -> HourlyWeatherPoint? in
            guard let date = calendar.date(byAdding: .hour, value: offset, to: now) else { return nil }
            return HourlyWeatherPoint(
                date: date,
                temperatureCelsius: 22 + Double(offset),
                apparentTemperatureCelsius: 22 + Double(offset),
                humidity: 0.45,
                windSpeedKph: 8,
                precipitationChance: 0.05,
                precipitationAmountMm: 0,
                uvIndex: 3,
                conditionCode: "clear",
                symbolName: "sun.max.fill",
                isDaylight: true,
                severeWeatherRisk: nil
            )
        }
        let daily = (0..<5).compactMap { offset -> DailyWeatherPoint? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { return nil }
            return DailyWeatherPoint(
                date: date,
                highTemperatureCelsius: 27,
                lowTemperatureCelsius: 17,
                precipitationChance: 0.10,
                uvIndex: 4,
                conditionCode: "clear",
                symbolName: "sun.max.fill",
                sunrise: calendar.date(bySettingHour: 6, minute: 15, second: 0, of: date),
                sunset: calendar.date(bySettingHour: 19, minute: 45, second: 0, of: date)
            )
        }

        return HomeRecommendationResult(
            recommendation: .placeholder,
            currentWeather: CurrentWeatherPoint(
                date: now,
                temperatureCelsius: 24,
                apparentTemperatureCelsius: 24,
                humidity: 0.45,
                windSpeedKph: 8,
                precipitationChance: 0.05,
                precipitationAmountMm: 0,
                uvIndex: 3,
                conditionCode: "clear",
                symbolName: "sun.max.fill",
                isDaylight: true,
                severeWeatherRisk: nil
            ),
            minutePoints: [],
            hourlyPoints: hourly,
            dailyPoints: daily,
            alerts: [],
            availability: nil,
            isUsingCachedWeather: false,
            warningMessage: nil,
            weatherFetchedAt: now,
            attribution: nil
        )
    }
}
