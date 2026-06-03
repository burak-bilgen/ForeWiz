import Foundation

@MainActor
@Observable
final class OnboardingViewModel {
    private(set) var selectedLanguage: AppLanguage = .english
    private(set) var locationStatus: LocationAuthorizationStatus = .notDetermined
    private(set) var notificationStatus: NotificationAuthorizationStatus = .notDetermined
    private(set) var trackingStatus: AdConsentManager.ConsentStatus = .notDetermined
    private(set) var errorMessage: String?
    var showTrackingSettingsAlert = false
    private(set) var profile: UserComfortProfile

    private let locationRepository: LocationRepository
    private let notificationRepository: NotificationRepository

    init(
        locationRepository: LocationRepository,
        notificationRepository: NotificationRepository,
        profile: UserComfortProfile = .default
    ) {
        self.locationRepository = locationRepository
        self.notificationRepository = notificationRepository
        self.profile = profile
        let currentCode = L10n.currentLanguageCode
        selectedLanguage = AppLanguage.allCases.first { $0.localeIdentifier == currentCode } ?? profile.language
        
        // Sync tracking status with actual ATT system state
        AdConsentManager.shared.updateConsentStatus()
        trackingStatus = AdConsentManager.shared.trackingStatus
    }

    var canContinue: Bool {
        locationStatus == .authorized || !profile.savedLocations.filter { $0.id != "current-location" }.isEmpty
    }

    func selectLanguage(_ lang: AppLanguage) {
        selectedLanguage = lang
        L10n.configure(language: lang)
        NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
    }

    func requestLocationPermission() {
        Task {
            let status = await locationRepository.requestAuthorization()
            locationStatus = status
            if status == .denied || status == .restricted {
                EventLogger.shared.track(.locationPermissionDenied)
                errorMessage = LocationPermissionMapper.userMessage(for: status)
            } else if status == .authorized {
                EventLogger.shared.track(.locationPermissionGranted)
                errorMessage = nil
            }
        }
    }

    func requestNotificationPermission() {
        Task {
            let status = await notificationRepository.requestAuthorization()
            notificationStatus = status
            if status == .authorized {
                EventLogger.shared.track(.notificationPermissionGranted)
            } else if status == .denied {
                EventLogger.shared.track(.notificationPermissionDenied)
            }
        }
    }

    func requestTrackingPermission() {
        Task {
            // Check if system-level ATT is disabled first
            if AdConsentManager.shared.isSystemTrackingDisabled {
                showTrackingSettingsAlert = true
                trackingStatus = .denied
                EventLogger.shared.track(.trackingPermissionDenied)
                return
            }
            
            let status = await AdConsentManager.shared.requestTrackingPermission()
            trackingStatus = status

            if AdConsentManager.shared.canServeAds {
                AdManager.shared.clearAllCaches()
                await AdManager.shared.preloadAllAds()
            }

            if status == .granted {
                EventLogger.shared.track(.trackingPermissionGranted)
            } else {
                EventLogger.shared.track(.trackingPermissionDenied)
            }
        }
    }
    
    func setErrorMessage(_ message: String?) {
        errorMessage = message
    }
    
    func dismissTrackingSettingsAlert() {
        showTrackingSettingsAlert = false
    }
    
    func addManualLocation(_ location: SavedLocation) {
        var updatedProfile = profile
        if !updatedProfile.savedLocations.contains(where: { $0.id == location.id }) {
            updatedProfile.savedLocations.append(location)
        }
        updatedProfile.selectedLocationID = location.id
        self.profile = updatedProfile
        self.errorMessage = nil
    }

    func makeProfile() -> UserComfortProfile {
        var updatedProfile = profile
        updatedProfile.language = selectedLanguage
        L10n.configure(language: selectedLanguage)
        return updatedProfile
    }
}
