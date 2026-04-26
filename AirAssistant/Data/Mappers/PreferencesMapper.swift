import Foundation

enum PreferencesMapper {
    static func domain(from stored: StoredUserPreferences) -> UserComfortProfile {
        stored.profile
    }
}
