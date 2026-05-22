import CoreLocation
import Foundation
import MapKit
import OSLog

@MainActor
@Observable
final class HomeViewModel {
    private(set) var state: LoadableState<HomeViewState> = .idle
    private(set) var selectedLocationName: String = L10n.text( "home_current_location")
    private(set) var particleIntensity: Double = 0.15

    private let loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase
    private let scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase
    private let preferencesRepository: PreferencesRepository
    private let homeViewStateFactory: HomeViewStateFactory
    private var didLoad = false
    @ObservationIgnored private var liveRetryTask: Task<Void, Never>?

    private var selectedLocation: SavedLocation?

    init(
        loadHomeRecommendationUseCase: LoadHomeRecommendationUseCase,
        scheduleSmartNotificationsUseCase: ScheduleSmartNotificationsUseCase,
        preferencesRepository: PreferencesRepository,
        homeViewStateFactory: HomeViewStateFactory,
        selectedLocationName: String = L10n.text( "home_current_location")
    ) {
        self.loadHomeRecommendationUseCase = loadHomeRecommendationUseCase
        self.scheduleSmartNotificationsUseCase = scheduleSmartNotificationsUseCase
        self.preferencesRepository = preferencesRepository
        self.homeViewStateFactory = homeViewStateFactory
        self.selectedLocationName = selectedLocationName
    }

    deinit {
        liveRetryTask?.cancel()
    }

    func onAppear() {
        guard didLoad == false else {
            return
        }

        didLoad = true
        Task {
            await load(forceRefresh: true, retryCachedResult: true)
        }
    }

    func reloadForLanguageChange() async {
        didLoad = false
        await load(forceRefresh: true, retryCachedResult: true)
        didLoad = true
    }

    func refresh() async {
        liveRetryTask?.cancel()
        await load(forceRefresh: true, retryCachedResult: true)
    }

    func refreshWhenAppBecomesActive() async {
        guard didLoad else {
            return
        }

        await load(forceRefresh: true, showsLoading: false, retryCachedResult: true)
    }

    func changeLocation(to location: SavedLocation) async {
        selectedLocation = location
        selectedLocationName = location.name

        do {
            var updatedProfile = try await preferencesRepository.loadProfile()
            updatedProfile.selectedLocationID = location.id
            try await preferencesRepository.saveProfile(updatedProfile)
        } catch {
            AppLogger.app.error("Failed to update location preference: \(error.localizedDescription)")
        }

        didLoad = false
        await load(forceRefresh: true, retryCachedResult: true)
    }

    private func load(
        forceRefresh: Bool,
        showsLoading: Bool = true,
        retryCachedResult: Bool = false
    ) async {
        let previousState = state
        if showsLoading {
            state = .loading
        }

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
            self.particleIntensity = profile.weatherParticleIntensity

            state = .loaded(
                homeViewStateFactory.makeViewState(
                    from: result,
                    profile: profile
                )
            )

            if result.isUsingCachedWeather, retryCachedResult {
                scheduleLiveRetry()
            } else if result.isUsingCachedWeather == false {
                liveRetryTask?.cancel()
            }

            if selectedLocation == nil || selectedLocation?.id == "current-location",
               let location = result.usedLocation {
                resolveLocationName(for: location)
            }

            do {
                _ = try await scheduleSmartNotificationsUseCase.execute(
                    recommendation: result.recommendation,
                    profile: profile,
                    hourlyPoints: result.hourlyPoints
                )
            } catch {
                AppLogger.notifications.error("Failed to schedule notifications: \(error.localizedDescription)")
            }
        } catch {
            if showsLoading {
                state = .failed(message(for: error))
            } else {
                state = previousState
            }
        }
    }

    private func scheduleLiveRetry() {
        liveRetryTask?.cancel()
        liveRetryTask = Task { [weak self] in
            // Base delays with added jitter (±25%) to avoid thundering herd
            // when multiple users' apps retry simultaneously
            let baseDelays = [6, 18, 45]
            for base in baseDelays {
                let jitter = Double.random(in: -0.25...0.25)
                let delay = Double(base) * (1.0 + jitter)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard Task.isCancelled == false else { return }
                guard await self?.retryLiveWeatherOnce() == true else {
                    return
                }
            }
        }
    }

    private func retryLiveWeatherOnce() async -> Bool {
        await load(forceRefresh: true, showsLoading: false, retryCachedResult: false)

        guard case .loaded(let state) = state else {
            return false
        }

        return state.isUsingCachedWeather
    }
    private func message(for error: any Error) -> String {
        if let appError = error as? AppError {
            return appError.userMessage
        }

        return AppError.unknown.userMessage
    }

    private func resolveLocationName(for location: LocationCoordinate) {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        guard let request = MKReverseGeocodingRequest(location: clLocation) else { return }
        Task {
            do {
                let mapItems = try await request.mapItems
                guard let item = mapItems.first else { return }
                let locationName = item.addressRepresentations?.cityName ?? item.address?.shortAddress ?? item.name ?? L10n.text("home_current_location")
                Task { @MainActor in
                    self.selectedLocationName = locationName
                }
            } catch {
                AppLogger.app.error("Reverse geocoding failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Feedback

    /// Records user feedback about the weather recommendation and persists the updated profile.
    func recordFeedback(_ feedback: UserWeatherFeedback) async {
        do {
            var profile = try await preferencesRepository.loadProfile()
            profile.recordFeedback(feedback)
            try await preferencesRepository.saveProfile(profile)
            AppLogger.app.info("Feedback recorded: \(feedback). Temp offset now: \(profile.temperatureOffset)")
        } catch {
            AppLogger.app.error("Failed to save feedback: \(error.localizedDescription)")
        }
    }

    /// Resets all learning data back to defaults.
    func resetLearning() async {
        do {
            var profile = try await preferencesRepository.loadProfile()
            profile.resetLearning()
            try await preferencesRepository.saveProfile(profile)
            AppLogger.app.info("Learning data reset")
        } catch {
            AppLogger.app.error("Failed to reset learning: \(error.localizedDescription)")
        }
    }

}
