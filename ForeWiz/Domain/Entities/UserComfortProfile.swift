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
    var weatherParticleIntensity: Double // 0 (kapalı) – 1 (maks), varsayılan 0.15

    init(
        usualWorkoutTime: DateComponents? = nil,
        quietHours: TimeWindow? = nil,
        notificationPreferences: [NotificationPreference],
        maximumDailyNotifications: Int = 2,
        appearance: AppAppearance = .system,
        accentPalette: AppAccentPalette = .sky,
        language: AppLanguage = .english,
        savedLocations: [SavedLocation] = [SavedLocation.currentLocation],
        selectedLocationID: String = "current-location",
        weatherParticleIntensity: Double = 0.15
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
        self.weatherParticleIntensity = weatherParticleIntensity.clamped(to: 0...1)
    }

    static var `default`: UserComfortProfile {
        UserComfortProfile(
            notificationPreferences: NotificationCategory.allCases.map {
                NotificationPreference(category: $0, isEnabled: true, preferredTime: nil)
            }
        )
    }
}
