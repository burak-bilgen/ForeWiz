import Foundation
import os

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
    private let weatherBriefingService: WeatherBriefingService
    private let presentationMapper: WeatherPresentationMapper
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
        cachePolicy: WeatherCachePolicy = WeatherCachePolicy(),
        weatherBriefingService: WeatherBriefingService = WeatherBriefingService(),
        presentationMapper: WeatherPresentationMapper = WeatherPresentationMapper()
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
        self.weatherBriefingService = weatherBriefingService
        self.presentationMapper = presentationMapper
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
             return await makeResult(snapshot: cached, profile: profile, now: now, isCached: true, usedLocation: cached.location)
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
            let result = await makeResult(snapshot: snapshot, profile: profile, now: now, isCached: false, usedLocation: location)
            cacheWidgetData(
                snapshot: snapshot,
                outdoorScore: result.recommendation.outdoorScore.rawValue,
                locationName: L10n.text("home_current_location")
            )
            return result
        } catch {
            guard let cached = try await usableCachedSnapshot(now: now) else {
                throw normalized(error)
            }

            return await makeResult(
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

        // Compute hourly temperature range for smart cache decisions
        let tempRange: Double? = {
            let temps = cached.hourly.map(\.temperatureCelsius)
            guard let min = temps.min(), let max = temps.max() else { return nil }
            return max - min
        }()

        switch cachePolicy.freshness(for: cached.fetchedAt, now: now, hourlyTempRange: tempRange) {
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
                
                // Exponential backoff with randomized jitter
                // attempt 1: base = 600ms, jitter = 0-150ms -> 600-750ms
                // attempt 2: base = 1200ms, jitter = 0-150ms -> 1200-1350ms
                let baseDelayMs = Double(1 << attempt) * 300.0
                let jitterMs = Double.random(in: 0...150.0)
                let delayNanoseconds = UInt64((baseDelayMs + jitterMs) * 1_000_000.0)
                
                try? await Task.sleep(nanoseconds: delayNanoseconds)
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
    ) async -> HomeRecommendationResult {
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

        // Generate daily briefing
        let briefing = await weatherBriefingService.generateBriefing(
            snapshot: snapshot,
            recommendation: recommendation,
            profile: profile
        )

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
            rankedCandidates: rankedCandidates,
            briefing: briefing
        )
    }

    private func normalized(_ error: any Error) -> AppError {
        ErrorHandler.normalized(error)
    }



    private func cacheWidgetData(snapshot: WeatherSnapshot, outdoorScore: Int, locationName: String) {
        let calendar = Calendar.current
        let locale = L10n.locale
        let dayFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = locale
            f.dateFormat = "EEE"
            return f
        }()

        let description = presentationMapper.conditionText(for: snapshot.current.conditionCode)

        let widgetData = WidgetCacheData(
            locationName: locationName,
            currentTemperature: snapshot.current.temperatureCelsius,
            currentConditionSymbol: snapshot.current.symbolName ?? "cloud.sun.fill",
            currentConditionDescription: description,
            outdoorScore: outdoorScore,
            dailyForecasts: snapshot.daily.map { day in
                let dayName = dayFormatter.string(from: day.date)
                return WidgetCacheDailyForecast(
                    date: day.date,
                    dayName: dayName,
                    highTemp: day.highTemperatureCelsius,
                    lowTemp: day.lowTemperatureCelsius,
                    conditionSymbol: day.symbolName ?? "cloud.sun.fill",
                    outdoorScore: presentationMapper.dailyScore(highCelsius: day.highTemperatureCelsius, lowCelsius: day.lowTemperatureCelsius, precipitationChance: day.precipitationChance),
                    isToday: calendar.isDateInToday(day.date),
                    precipitationChance: day.precipitationChance ?? 0
                )
            },
            lastUpdated: snapshot.fetchedAt,
            attributionName: snapshot.attribution?.serviceName ?? "Weather",
            languageCode: L10n.currentLanguageCode
        )

        guard let defaults = UserDefaults(suiteName: "group.forewiz"),
              let encoded = try? JSONEncoder().encode(widgetData) else { return }

        // Use shared-container key if available, fall back to deterministic key
        let key = WidgetKeyManager.loadOrCreateKey()
        do {
            let encrypted = try WidgetDataCrypto.encrypt(encoded, key: key)
            defaults.set(encrypted, forKey: "com.forewiz.widget.weatherData")
        } catch {
            AppLogger.app.error("Failed to encrypt widget data: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Widget Cache Models

    private struct WidgetCacheData: Codable {
        let locationName: String
        let currentTemperature: Double
        let currentConditionSymbol: String
        let currentConditionDescription: String
        let outdoorScore: Int
        let dailyForecasts: [WidgetCacheDailyForecast]
        let lastUpdated: Date
        let attributionName: String
        let languageCode: String
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
}
