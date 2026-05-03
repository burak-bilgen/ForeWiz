import Foundation

final class SwiftDataPreferencesRepository: PreferencesRepository {
    private enum Key {
        static let profile = "weatherassistant.profile.v1"
        static let onboardingCompleted = "weatherassistant.onboardingCompleted.v1"
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadProfile() async throws -> UserComfortProfile {
        guard let data = userDefaults.data(forKey: Key.profile) else {
            return .default
        }

        do {
            return try decoder.decode(UserComfortProfile.self, from: data)
        } catch {
            throw AppError.persistenceFailed
        }
    }

    func saveProfile(_ profile: UserComfortProfile) async throws {
        do {
            let data = try encoder.encode(profile)
            userDefaults.set(data, forKey: Key.profile)
        } catch {
            throw AppError.persistenceFailed
        }
    }

    func isOnboardingCompleted() async throws -> Bool {
        userDefaults.bool(forKey: Key.onboardingCompleted)
    }

    func setOnboardingCompleted(_ completed: Bool) async throws {
        userDefaults.set(completed, forKey: Key.onboardingCompleted)
    }
}
