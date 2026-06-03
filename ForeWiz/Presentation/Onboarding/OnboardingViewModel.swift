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

    private(set) var homeLocation: SavedLocation?
    private(set) var workLocation: SavedLocation?
    private(set) var commuteModeRaw: String = TravelMode.car.rawValue

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
        self.homeLocation = profile.homeLocation
        self.workLocation = profile.workLocation
        if let home = profile.homeLocation {
            self.commuteModeRaw = home.commuteModeRaw
        }
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

    func setHomeLocation(_ location: SavedLocation) {
        homeLocation = location
        var updated = location
        updated.locationType = .home
        updated.commuteModeRaw = commuteModeRaw
        homeLocation = updated
    }

    func setWorkLocation(_ location: SavedLocation) {
        workLocation = location
        var updated = location
        updated.locationType = .work
        workLocation = updated
    }

    func clearHomeLocation() {
        homeLocation = nil
    }

    func clearWorkLocation() {
        workLocation = nil
    }

    func setCommuteMode(_ mode: TravelMode) {
        commuteModeRaw = mode.rawValue
        if var home = homeLocation {
            home.commuteModeRaw = mode.rawValue
            homeLocation = home
        }
    }

    func makeProfile() -> UserComfortProfile {
        var updatedProfile = profile
        updatedProfile.language = selectedLanguage
        updatedProfile.homeLocation = homeLocation
        updatedProfile.workLocation = workLocation

        if var home = homeLocation {
            home.commuteModeRaw = commuteModeRaw
            updatedProfile.homeLocation = home
        }

        L10n.configure(language: selectedLanguage)
        return updatedProfile
    }
}
