import Foundation

struct StoredUserPreferences: Codable, Equatable {
    let profile: UserComfortProfile
    let onboardingCompleted: Bool
}
