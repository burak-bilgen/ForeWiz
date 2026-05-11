import Foundation

struct UserComfortProfile: Codable, Equatable, Sendable {
    var temperatureSensitivity: TemperatureSensitivity
    var preferredActivities: Set<ActivityType>
    var wakeUpTime: DateComponents?
    var usualWorkoutTime: DateComponents?
    var quietHours: TimeWindow?
    var notificationPreferences: [NotificationPreference]
    var unitSystem: UnitSystem
    var maximumDailyNotifications: Int
    var appearance: AppAppearance
    var accentPalette: AppAccentPalette
    var language: AppLanguage
    var savedLocations: [SavedLocation]
    var selectedLocationID: String

    private enum CodingKeys: String, CodingKey {
        case temperatureSensitivity
        case preferredActivities
        case wakeUpTime
        case usualWorkoutTime
        case quietHours
        case notificationPreferences
        case unitSystem
        case maximumDailyNotifications
        case appearance
        case accentPalette
        case language
        case savedLocations
        case selectedLocationID
    }

    init(
        temperatureSensitivity: TemperatureSensitivity,
        preferredActivities: Set<ActivityType>,
        wakeUpTime: DateComponents? = nil,
        usualWorkoutTime: DateComponents? = nil,
        quietHours: TimeWindow? = nil,
        notificationPreferences: [NotificationPreference],
        unitSystem: UnitSystem = .metric,
        maximumDailyNotifications: Int = 2,
        appearance: AppAppearance = .system,
        accentPalette: AppAccentPalette = .sky,
        language: AppLanguage = .system,
        savedLocations: [SavedLocation] = [SavedLocation.currentLocation],
        selectedLocationID: String = "current-location"
    ) {
        self.temperatureSensitivity = temperatureSensitivity
        self.preferredActivities = preferredActivities
        self.wakeUpTime = wakeUpTime
        self.usualWorkoutTime = usualWorkoutTime
        self.quietHours = quietHours
        self.notificationPreferences = notificationPreferences
        self.unitSystem = unitSystem
        self.maximumDailyNotifications = maximumDailyNotifications.clamped(to: 1...3)
        self.appearance = appearance
        self.accentPalette = accentPalette
        self.language = language
        self.savedLocations = savedLocations
        self.selectedLocationID = selectedLocationID
    }

    static var `default`: UserComfortProfile {
        UserComfortProfile(
            temperatureSensitivity: .normal,
            preferredActivities: [.running, .walking, .goingOutside],
            notificationPreferences: NotificationCategory.allCases.map {
                NotificationPreference(category: $0, isEnabled: true, preferredTime: nil)
            }
        )
    }
}
