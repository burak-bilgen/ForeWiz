import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var selectedSensitivity: TemperatureSensitivity = .normal
    @Published private(set) var preferredActivities: Set<ActivityType> = [.walking, .goingOutside]
    @Published private(set) var selectedAllergies: Set<AllergyType> = []
    @Published private(set) var selectedPollenTypes: Set<PollenType> = Set(PollenType.allCases)
    @Published private(set) var locationStatus: LocationAuthorizationStatus = .notDetermined
    @Published private(set) var notificationStatus: NotificationAuthorizationStatus = .notDetermined
    @Published private(set) var errorMessage: String?

    private let locationRepository: LocationRepository
    private let notificationRepository: NotificationRepository

    init(
        locationRepository: LocationRepository,
        notificationRepository: NotificationRepository,
        profile: UserComfortProfile = .default
    ) {
        self.locationRepository = locationRepository
        self.notificationRepository = notificationRepository
        selectedSensitivity = profile.temperatureSensitivity
        preferredActivities = profile.preferredActivities
        selectedAllergies = profile.allergyProfile.allergies
        selectedPollenTypes = profile.allergyProfile.pollenTypes
    }

    var canContinue: Bool {
        locationStatus == .authorized
    }

    func selectSensitivity(_ sensitivity: TemperatureSensitivity) {
        selectedSensitivity = sensitivity
    }

    func toggleActivity(_ activity: ActivityType) {
        if preferredActivities.contains(activity) {
            preferredActivities.remove(activity)
        } else {
            preferredActivities.insert(activity)
        }

        if preferredActivities.isEmpty {
            preferredActivities.insert(.goingOutside)
        }
    }

    func toggleAllergy(_ allergy: AllergyType) {
        if selectedAllergies.contains(allergy) {
            selectedAllergies.remove(allergy)
        } else {
            selectedAllergies.insert(allergy)
        }
    }

    func togglePollenType(_ pollenType: PollenType) {
        if selectedPollenTypes.contains(pollenType) {
            selectedPollenTypes.remove(pollenType)
        } else {
            selectedPollenTypes.insert(pollenType)
        }

        if selectedPollenTypes.isEmpty {
            selectedPollenTypes.insert(pollenType)
        }
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
        profile.temperatureSensitivity = selectedSensitivity
        profile.preferredActivities = preferredActivities.isEmpty ? [.goingOutside] : preferredActivities
        profile.allergyProfile = AllergyProfile(
            allergies: selectedAllergies,
            pollenTypes: selectedPollenTypes,
            isEnabled: selectedAllergies.isEmpty == false
        )
        return profile
    }
}
