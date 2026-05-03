import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var selectedSensitivity: TemperatureSensitivity = .normal
    @Published private(set) var preferredActivities: Set<ActivityType> = [.walking, .goingOutside]
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
    }

    func requestLocationPermission() {
        Task {
            let status = await locationRepository.requestAuthorization()
            locationStatus = status
            if status == .denied || status == .restricted {
                errorMessage = LocationPermissionMapper.userMessage(for: status)
            } else {
                errorMessage = nil
            }
        }
    }

    func requestNotificationPermission() {
        Task {
            notificationStatus = await notificationRepository.requestAuthorization()
        }
    }

    func setErrorMessage(_ message: String?) {
        errorMessage = message
    }

    func makeProfile(inheriting existingProfile: UserComfortProfile = .default) -> UserComfortProfile {
        var profile = existingProfile
        profile.temperatureSensitivity = selectedSensitivity
        profile.preferredActivities = preferredActivities.isEmpty ? [.goingOutside] : preferredActivities
        return profile
    }
}
