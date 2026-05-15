import Foundation

@MainActor
@Observable
final class OnboardingViewModel {
    private(set) var selectedSensitivity: TemperatureSensitivity = .normal
    private(set) var preferredActivities: Set<ActivityType> = [.walking, .goingOutside]
    private(set) var wakeUpTime: DateComponents
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
        selectedSensitivity = profile.temperatureSensitivity
        preferredActivities = profile.preferredActivities
        wakeUpTime = profile.wakeUpTime ?? Self.defaultWakeTime()
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

    func setWakeUpHour(_ hour: Int) {
        wakeUpTime = DateComponents(hour: hour, minute: 0)
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
        profile.wakeUpTime = wakeUpTime
        return profile
    }

    private static func defaultWakeTime() -> DateComponents {
        DateComponents(hour: 7, minute: 0)
    }
}
