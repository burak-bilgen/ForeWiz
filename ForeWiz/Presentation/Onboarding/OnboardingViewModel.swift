import Foundation

@MainActor
@Observable
final class OnboardingViewModel {
    private(set) var selectedLanguage: AppLanguage = .english
    private(set) var locationStatus: LocationAuthorizationStatus = .notDetermined
    private(set) var notificationStatus: NotificationAuthorizationStatus = .notDetermined
    private(set) var errorMessage: String?

    private let locationRepository: LocationRepository
    private let notificationRepository: NotificationRepository

    init(
        locationRepository: LocationRepository,
        notificationRepository: NotificationRepository,
        profile: UserComfortProfile = .default
    ) {
        self.locationRepository = locationRepository
        self.notificationRepository = notificationRepository
        let code = L10n.currentLanguageCode
        selectedLanguage = code == "tr" ? .turkish : .english
    }

    var canContinue: Bool {
        locationStatus == .authorized
    }

    func selectLanguage(_ lang: AppLanguage) {
        selectedLanguage = lang
        L10n.configure(language: lang)
    }

    func requestLocationPermission() {
        Task {
            let status = await locationRepository.requestAuthorization()
            locationStatus = status
            if status == .denied || status == .restricted {
                AnalyticsManager.shared.track(.locationPermissionDenied)
                errorMessage = LocationPermissionMapper.userMessage(for: status)
            } else if status == .authorized {
                AnalyticsManager.shared.track(.locationPermissionGranted)
                errorMessage = nil
            }
        }
    }

    func requestNotificationPermission() {
        Task {
            let status = await notificationRepository.requestAuthorization()
            notificationStatus = status
            if status == .authorized {
                AnalyticsManager.shared.track(.notificationPermissionGranted)
            } else if status == .denied {
                AnalyticsManager.shared.track(.notificationPermissionDenied)
            }
        }
    }

    func setErrorMessage(_ message: String?) {
        errorMessage = message
    }

    func makeProfile(inheriting existingProfile: UserComfortProfile = .default) -> UserComfortProfile {
        var profile = existingProfile
        profile.language = selectedLanguage
        return profile
    }
}
