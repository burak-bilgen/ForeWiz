import Foundation

struct UserComfortProfile: Codable, Equatable, Sendable {
    var usualWorkoutTime: DateComponents?
    var quietHours: TimeWindow?
    var notificationPreferences: [NotificationPreference]
    var maximumDailyNotifications: Int
    var appearance: AppAppearance
    var accentPalette: AppAccentPalette
    var language: AppLanguage
    var savedLocations: [SavedLocation]
    var selectedLocationID: String

    init(
        usualWorkoutTime: DateComponents? = nil,
        quietHours: TimeWindow? = nil,
        notificationPreferences: [NotificationPreference],
        maximumDailyNotifications: Int = 2,
        appearance: AppAppearance = .system,
        accentPalette: AppAccentPalette = .sky,
        language: AppLanguage = .system,
        savedLocations: [SavedLocation] = [SavedLocation.currentLocation],
        selectedLocationID: String = "current-location"
    ) {
        self.usualWorkoutTime = usualWorkoutTime
        self.quietHours = quietHours
        self.notificationPreferences = notificationPreferences
        self.maximumDailyNotifications = maximumDailyNotifications.clamped(to: 1...3)
        self.appearance = appearance
        self.accentPalette = accentPalette
        self.language = language
        self.savedLocations = savedLocations
        self.selectedLocationID = selectedLocationID
    }

    static var `default`: UserComfortProfile {
        UserComfortProfile(
            notificationPreferences: NotificationCategory.allCases.map {
                NotificationPreference(category: $0, isEnabled: true, preferredTime: nil)
            }
        )
    }
}
