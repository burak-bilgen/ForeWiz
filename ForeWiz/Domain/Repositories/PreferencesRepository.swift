import Foundation

protocol PreferencesRepository {
    func loadProfile() async throws -> UserComfortProfile
    func saveProfile(_ profile: UserComfortProfile) async throws
    func isOnboardingCompleted() async throws -> Bool
    func setOnboardingCompleted(_ completed: Bool) async throws
    func deleteAll() async throws
}
