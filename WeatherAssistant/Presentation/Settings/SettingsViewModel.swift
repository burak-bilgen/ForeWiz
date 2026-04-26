import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profile: UserComfortProfile

    init(profile: UserComfortProfile) {
        self.profile = profile
    }
}
