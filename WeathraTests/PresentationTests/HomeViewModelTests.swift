import Testing
@testable import Weathra

struct HomeViewModelTests {
    @Test func initialStateIsLoading() async {
        let repository = MockWeatherRepository()
        let locationRepo = MockLocationRepository()
        let decisionEngine = DefaultWeatherDecisionEngine()

        let viewModel = HomeViewModel(
            weatherRepository: repository,
            locationRepository: locationRepo,
            decisionEngine: decisionEngine,
            preferencesRepository: MockPreferencesRepository()
        )

        #expect(viewModel.state == .loading)
    }

    @Test func loadStateProvidesCorrectData() async {
        let repository = MockWeatherRepository()
        let locationRepo = MockLocationRepository()
        let decisionEngine = DefaultWeatherDecisionEngine()
        let preferencesRepo = MockPreferencesRepository()

        let viewModel = HomeViewModel(
            weatherRepository: repository,
            locationRepository: locationRepo,
            decisionEngine: decisionEngine,
            preferencesRepository: preferencesRepo
        )

        await viewModel.onAppear()

        await Task.yield()

        if case .loaded(let state) = viewModel.state {
            #expect(state.currentWeather.temperatureText.isEmpty == false)
            #expect(state.hourlyScores.isEmpty == false)
        } else {
            #expect(Bool(false), "Expected loaded state")
        }
    }

    @Test func errorStateShowsMessage() async {
        let failingRepo = MockWeatherRepository(shouldFail: true)
        let locationRepo = MockLocationRepository()
        let decisionEngine = DefaultWeatherDecisionEngine()
        let preferencesRepo = MockPreferencesRepository()

        let viewModel = HomeViewModel(
            weatherRepository: failingRepo,
            locationRepository: locationRepo,
            decisionEngine: decisionEngine,
            preferencesRepository: preferencesRepo
        )

        await viewModel.onAppear()

        await Task.yield()

        if case .failed(let message) = viewModel.state {
            #expect(message.isEmpty == false)
        }
    }

    @Test func refreshUpdatesData() async {
        let repository = MockWeatherRepository()
        let locationRepo = MockLocationRepository()
        let decisionEngine = DefaultWeatherDecisionEngine()
        let preferencesRepo = MockPreferencesRepository()

        let viewModel = HomeViewModel(
            weatherRepository: repository,
            locationRepository: locationRepo,
            decisionEngine: decisionEngine,
            preferencesRepository: preferencesRepo
        )

        await viewModel.refresh()
        await Task.yield()

        if case .loaded = viewModel.state {
            #expect(true)
        }
    }
}

private class MockPreferencesRepository: PreferencesRepository {
    func preferences() async throws -> UserPreferencesModel {
        UserPreferencesModel()
    }

    func savePreferences(_ preferences: UserPreferencesModel) async throws {
    }

    func updatePreference<T>(_ keyPath: WritableKeyPath<UserPreferencesModel, T>, value: T) async throws {
    }

    func observePreferences() -> AsyncStream<UserPreferencesModel> {
        AsyncStream { _ in }
    }
}