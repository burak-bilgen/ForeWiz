import Foundation

final class SwiftDataPreferencesRepository: PreferencesRepository {
    private var storedProfile = UserComfortProfile.default
    private var onboardingCompleted = false

    func loadProfile() async throws -> UserComfortProfile {
        storedProfile
    }

    func saveProfile(_ profile: UserComfortProfile) async throws {
        storedProfile = profile
    }

    func isOnboardingCompleted() async throws -> Bool {
        onboardingCompleted
    }

    func setOnboardingCompleted(_ completed: Bool) async throws {
        onboardingCompleted = completed
    }
}
