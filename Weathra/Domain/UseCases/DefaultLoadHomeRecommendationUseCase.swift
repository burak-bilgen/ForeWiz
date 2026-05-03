import Foundation

final class DefaultLoadHomeRecommendationUseCase: LoadHomeRecommendationUseCase {
    private let locationRepository: LocationRepository
    private let weatherRepository: WeatherRepository
    private let weatherCacheRepository: WeatherCacheRepository
    private let preferencesRepository: PreferencesRepository
    private let weatherDecisionEngine: WeatherDecisionEngine
    private let dateProvider: DateProvider
    private let cachePolicy: WeatherCachePolicy

    init(
        locationRepository: LocationRepository,
        weatherRepository: WeatherRepository,
        weatherCacheRepository: WeatherCacheRepository,
        preferencesRepository: PreferencesRepository,
        weatherDecisionEngine: WeatherDecisionEngine,
        dateProvider: DateProvider,
        cachePolicy: WeatherCachePolicy = WeatherCachePolicy()
    ) {
        self.locationRepository = locationRepository
        self.weatherRepository = weatherRepository
        self.weatherCacheRepository = weatherCacheRepository
        self.preferencesRepository = preferencesRepository
        self.weatherDecisionEngine = weatherDecisionEngine
        self.dateProvider = dateProvider
        self.cachePolicy = cachePolicy
    }

    func execute(forceRefresh: Bool) async throws -> HomeRecommendationResult {
        let now = dateProvider.now
        let profile = try await preferencesRepository.loadProfile()

        if forceRefresh == false,
           let cached = try await weatherCacheRepository.loadLatest(),
           cachePolicy.freshness(for: cached.fetchedAt, now: now) == .fresh {
            return makeResult(snapshot: cached, profile: profile, now: now, isCached: true)
        }

        do {
            let authorizationStatus = await locationRepository.requestAuthorization()
            guard authorizationStatus == .authorized else {
                throw AppError.locationPermissionDenied
            }

            let location = try await locationRepository.getCurrentLocation()
            let snapshot = try await weatherRepository.fetchWeather(for: location)
            try await weatherCacheRepository.save(snapshot)
            return makeResult(snapshot: snapshot, profile: profile, now: now, isCached: false)
        } catch {
            guard let cached = try await usableCachedSnapshot(now: now) else {
                throw normalized(error)
            }

            return makeResult(
                snapshot: cached,
                profile: profile,
                now: now,
                isCached: true,
                warningMessage: "Canlı tahmin alınamadı; en son kayıtlı hava gösteriliyor."
            )
        }
    }

    private func usableCachedSnapshot(now: Date) async throws -> WeatherSnapshot? {
        guard let cached = try await weatherCacheRepository.loadLatest() else {
            return nil
        }

        switch cachePolicy.freshness(for: cached.fetchedAt, now: now) {
        case .fresh, .staleUsable:
            return cached
        case .expired:
            return nil
        }
    }

    private func makeResult(
        snapshot: WeatherSnapshot,
        profile: UserComfortProfile,
        now: Date,
        isCached: Bool,
        warningMessage: String? = nil
    ) -> HomeRecommendationResult {
        let recommendation = weatherDecisionEngine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: profile,
            now: now,
            calendar: .current
        )

        return HomeRecommendationResult(
            recommendation: recommendation,
            currentWeather: snapshot.current,
            isUsingCachedWeather: isCached,
            warningMessage: warningMessage,
            weatherFetchedAt: snapshot.fetchedAt,
            attribution: snapshot.attribution
        )
    }

    private func normalized(_ error: any Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        return .unknown
    }
}
