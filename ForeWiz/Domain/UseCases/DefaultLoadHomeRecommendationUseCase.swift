import Foundation

final class DefaultLoadHomeRecommendationUseCase: LoadHomeRecommendationUseCase {
    private let locationRepository: LocationRepository
    private let weatherRepository: WeatherRepository
    private let weatherCacheRepository: WeatherCacheRepository
    private let preferencesRepository: PreferencesRepository
    private let weatherDecisionEngine: WeatherDecisionEngine
    private let candidateProvider: RecommendationCandidateProvider
    private let ranker: RecommendationRanker
    private let explainer: RecommendationExplainer
    private let store: RecommendationStore
    private let dateProvider: DateProvider
    private let cachePolicy: WeatherCachePolicy
    private let liveFetchAttempts = 3

    init(
        locationRepository: LocationRepository,
        weatherRepository: WeatherRepository,
        weatherCacheRepository: WeatherCacheRepository,
        preferencesRepository: PreferencesRepository,
        weatherDecisionEngine: WeatherDecisionEngine,
        candidateProvider: RecommendationCandidateProvider = DefaultRecommendationCandidateProvider(),
        ranker: RecommendationRanker = ContextualRecommendationRanker(),
        explainer: RecommendationExplainer = DefaultRecommendationExplainer(),
        store: RecommendationStore = DefaultRecommendationStore(),
        dateProvider: DateProvider,
        cachePolicy: WeatherCachePolicy = WeatherCachePolicy()
    ) {
        self.locationRepository = locationRepository
        self.weatherRepository = weatherRepository
        self.weatherCacheRepository = weatherCacheRepository
        self.preferencesRepository = preferencesRepository
        self.weatherDecisionEngine = weatherDecisionEngine
        self.candidateProvider = candidateProvider
        self.ranker = ranker
        self.explainer = explainer
        self.store = store
        self.dateProvider = dateProvider
        self.cachePolicy = cachePolicy
    }

    func execute(
        forceRefresh: Bool,
        targetLocation: LocationCoordinate? = nil
    ) async throws -> HomeRecommendationResult {
        let now = dateProvider.now
        let profile = try await preferencesRepository.loadProfile()

        if forceRefresh == false,
           let cached = try await weatherCacheRepository.loadLatest(),
           cachePolicy.freshness(for: cached.fetchedAt, now: now) == .fresh {
            return makeResult(snapshot: cached, profile: profile, now: now, isCached: true, usedLocation: cached.location)
        }

        do {
            let location: LocationCoordinate
            if let targetLocation {
                location = targetLocation
            } else {
                let authorizationStatus = await locationRepository.requestAuthorization()
                guard authorizationStatus == .authorized else {
                    throw AppError.locationPermissionDenied
                }
                location = try await locationRepository.getCurrentLocation()
            }

            let snapshot = try await fetchLiveWeather(for: location)
            try await weatherCacheRepository.save(snapshot)
            let result = makeResult(snapshot: snapshot, profile: profile, now: now, isCached: false, usedLocation: location)
            cacheWidgetData(
                snapshot: snapshot,
                outdoorScore: result.recommendation.outdoorScore.rawValue,
                locationName: "Current Location"
            )
            return result
        } catch {
            guard let cached = try await usableCachedSnapshot(now: now) else {
                throw normalized(error)
            }

            return makeResult(
                snapshot: cached,
                profile: profile,
                now: now,
                isCached: true,
                usedLocation: cached.location,
                warningMessage: L10n.text("error_live_forecast")
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

    private func fetchLiveWeather(for location: LocationCoordinate) async throws -> WeatherSnapshot {
        var lastError: (any Error)?

        for attempt in 1...liveFetchAttempts {
            do {
                return try await weatherRepository.fetchWeather(for: location)
            } catch {
                lastError = error
                guard attempt < liveFetchAttempts else { break }
                let delay = UInt64(attempt) * 650_000_000
                try? await Task.sleep(nanoseconds: delay)
            }
        }

        throw lastError ?? AppError.weatherUnavailable
    }

    private func makeResult(
        snapshot: WeatherSnapshot,
        profile: UserComfortProfile,
        now: Date,
        isCached: Bool,
        usedLocation: LocationCoordinate?,
        warningMessage: String? = nil
    ) -> HomeRecommendationResult {
        let recommendation = weatherDecisionEngine.makeDailyRecommendation(
            snapshot: snapshot,
            profile: profile,
            now: now,
            calendar: .current
        )

        let context = RecommendationContext(
            timeOfDay: RecommendationContext.TimeOfDay(date: now),
            dayOfWeek: RecommendationContext.DayOfWeek(date: now),
            recentFeedback: store.recentFeedback(),
            lastShownTypes: store.lastShownTypes(),
            isOffline: isCached
        )

        let candidates = candidateProvider.candidates(
            from: snapshot,
            profile: profile,
            now: now,
            calendar: .current
        )

        let rankedCandidates = ranker.rank(candidates, context: context)
        store.saveCandidates(rankedCandidates)

        return HomeRecommendationResult(
            recommendation: recommendation,
            currentWeather: snapshot.current,
            minutePoints: snapshot.minute ?? [],
            hourlyPoints: snapshot.hourly,
            dailyPoints: snapshot.daily,
            alerts: snapshot.alerts ?? [],
            availability: snapshot.availability,
            isUsingCachedWeather: isCached,
            usedLocation: usedLocation,
            warningMessage: warningMessage,
            weatherFetchedAt: snapshot.fetchedAt,
            attribution: snapshot.attribution,
            rankedCandidates: rankedCandidates
        )
    }

    private func normalized(_ error: any Error) -> AppError {
        ErrorHandler.normalized(error)
    }

    private struct WidgetCacheData: Codable {
        let locationName: String
        let currentTemperature: Double
        let currentConditionSymbol: String
        let currentConditionDescription: String
        let outdoorScore: Int
        let dailyForecasts: [WidgetCacheDailyForecast]
        let lastUpdated: Date
        let attributionName: String
    }

    private struct WidgetCacheDailyForecast: Codable {
        let date: Date
        let dayName: String
        let highTemp: Double
        let lowTemp: Double
        let conditionSymbol: String
        let outdoorScore: Int
        let isToday: Bool
        let precipitationChance: Double
    }

    private func cacheWidgetData(snapshot: WeatherSnapshot, outdoorScore: Int, locationName: String) {
        let calendar = Calendar.current
        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        let condition = snapshot.current.conditionCode?.lowercased() ?? ""
        let description: String
        if condition.contains("thunder") || condition.contains("storm") { description = "Thunderstorm" }
        else if condition.contains("rain") || condition.contains("drizzle") { description = "Rain" }
        else if condition.contains("snow") || condition.contains("sleet") { description = "Snow" }
        else if condition.contains("cloud") { description = "Cloudy" }
        else if condition.contains("fog") || condition.contains("haze") { description = "Fog" }
        else if condition.contains("clear") || condition.contains("sun") { description = "Clear" }
        else { description = "—" }

        func score(for day: DailyWeatherPoint) -> Int {
            var s = 100.0
            s -= abs(day.highTemperatureCelsius - 24) * 1.8
            s -= abs(15 - day.lowTemperatureCelsius) * 1.8
            if let precip = day.precipitationChance {
                s -= precip * 0.55
            }
            return Int(max(0, min(100, s)))
        }

        let widgetData = WidgetCacheData(
            locationName: locationName,
            currentTemperature: snapshot.current.temperatureCelsius,
            currentConditionSymbol: snapshot.current.symbolName ?? "cloud.sun.fill",
            currentConditionDescription: description,
            outdoorScore: outdoorScore,
            dailyForecasts: snapshot.daily.map { day in
                let idx = calendar.component(.weekday, from: day.date) - 1
                let dayName = weekdays.indices.contains(idx) ? weekdays[idx] : "?"
                return WidgetCacheDailyForecast(
                    date: day.date,
                    dayName: dayName,
                    highTemp: day.highTemperatureCelsius,
                    lowTemp: day.lowTemperatureCelsius,
                    conditionSymbol: day.symbolName ?? "cloud.sun.fill",
                    outdoorScore: score(for: day),
                    isToday: calendar.isDateInToday(day.date),
                    precipitationChance: day.precipitationChance ?? 0
                )
            },
            lastUpdated: snapshot.fetchedAt,
            attributionName: snapshot.attribution?.serviceName ?? "Weather"
        )

        guard let defaults = UserDefaults(suiteName: "group.forewiz"),
              let encoded = try? JSONEncoder().encode(widgetData) else { return }
        defaults.set(encoded, forKey: "com.forewiz.widget.weatherData")
    }
}
