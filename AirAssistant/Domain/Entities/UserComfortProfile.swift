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

    init(
        temperatureSensitivity: TemperatureSensitivity,
        preferredActivities: Set<ActivityType>,
        wakeUpTime: DateComponents? = nil,
        usualWorkoutTime: DateComponents? = nil,
        quietHours: TimeWindow? = nil,
        notificationPreferences: [NotificationPreference],
        unitSystem: UnitSystem = .metric,
        maximumDailyNotifications: Int = 2
    ) {
        self.temperatureSensitivity = temperatureSensitivity
        self.preferredActivities = preferredActivities
        self.wakeUpTime = wakeUpTime
        self.usualWorkoutTime = usualWorkoutTime
        self.quietHours = quietHours
        self.notificationPreferences = notificationPreferences
        self.unitSystem = unitSystem
        self.maximumDailyNotifications = maximumDailyNotifications.clamped(to: 1...3)
    }

    static var `default`: UserComfortProfile {
        UserComfortProfile(
            temperatureSensitivity: .normal,
            preferredActivities: [.walking, .goingOutside],
            notificationPreferences: NotificationCategory.allCases.map {
                NotificationPreference(category: $0, isEnabled: true, preferredTime: nil)
            }
        )
    }
}
