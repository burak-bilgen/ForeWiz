import Foundation
import UIKit

@MainActor
@Observable
final class OnboardingViewModel {
    private(set) var selectedLanguage: AppLanguage = .english
    private(set) var locationStatus: LocationAuthorizationStatus = .notDetermined
    private(set) var notificationStatus: NotificationAuthorizationStatus = .notDetermined
    private(set) var trackingStatus: AdConsentManager.ConsentStatus = .notDetermined
    private(set) var errorMessage: String?
    var showTrackingSettingsAlert = false

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
        
        // Sync tracking status with actual ATT system state
        AdConsentManager.shared.updateConsentStatus()
        trackingStatus = AdConsentManager.shared.trackingStatus
    }

    var canContinue: Bool {
        locationStatus == .authorized
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

    func requestTrackingPermission() {
        Task {
            // Check if system-level ATT is disabled first
            if AdConsentManager.shared.isSystemTrackingDisabled {
                showTrackingSettingsAlert = true
                trackingStatus = .denied
                AnalyticsManager.shared.track(.trackingPermissionDenied)
                return
            }
            
            let status = await AdConsentManager.shared.requestTrackingPermission()
            trackingStatus = status
            if status == .granted {
                AnalyticsManager.shared.track(.trackingPermissionGranted)
            } else {
                AnalyticsManager.shared.track(.trackingPermissionDenied)
            }
        }
    }
    
    func setErrorMessage(_ message: String?) {
        errorMessage = message
    }
    
    func dismissTrackingSettingsAlert() {
        showTrackingSettingsAlert = false
    }
    
    func openTrackingSettings() {
        showTrackingSettingsAlert = false
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func makeProfile(inheriting existingProfile: UserComfortProfile = .default) -> UserComfortProfile {
        var profile = existingProfile
        profile.language = selectedLanguage
        L10n.configure(language: selectedLanguage)
        return profile
    }
}
