import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var selectedSensitivity: TemperatureSensitivity = .normal
    @Published private(set) var preferredActivities: Set<ActivityType> = [.walking, .goingOutside]

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
}
