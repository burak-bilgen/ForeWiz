import Foundation
import SwiftData

@Model
final class UserPreferencesModel {
    @Attribute(.unique) var id: UUID
    var temperatureSensitivityRaw: String
    var preferredActivitiesRaw: [String]
    var quietHoursStartHour: Int
    var quietHoursStartMinute: Int
    var quietHoursEndHour: Int
    var quietHoursEndMinute: Int
    var quietHoursEnabled: Bool
    var onboardingCompleted: Bool
    var preferredLanguageRaw: String?
    var preferredAppearanceRaw: String?
    var preferredUnitSystemRaw: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        temperatureSensitivity: TemperatureSensitivity,
        preferredActivities: [ActivityType],
        quietHours: TimeWindow? = nil,
        onboardingCompleted: Bool = false,
        preferredLanguage: AppLanguage? = nil,
        preferredAppearance: AppAppearance? = nil,
        preferredUnitSystem: UnitSystem? = nil
    ) {
        self.id = id
        self.temperatureSensitivityRaw = temperatureSensitivity.rawValue
        self.preferredActivitiesRaw = preferredActivities.map { $0.rawValue }
        
        if let quietHours {
            let calendar = Calendar.current
            self.quietHoursStartHour = calendar.component(.hour, from: quietHours.start)
            self.quietHoursStartMinute = calendar.component(.minute, from: quietHours.start)
            self.quietHoursEndHour = calendar.component(.hour, from: quietHours.end)
            self.quietHoursEndMinute = calendar.component(.minute, from: quietHours.end)
            self.quietHoursEnabled = true
        } else {
            self.quietHoursStartHour = 22
            self.quietHoursStartMinute = 0
            self.quietHoursEndHour = 8
            self.quietHoursEndMinute = 0
            self.quietHoursEnabled = false
        }
        
        self.onboardingCompleted = onboardingCompleted
        self.preferredLanguageRaw = preferredLanguage?.rawValue
        self.preferredAppearanceRaw = preferredAppearance?.rawValue
        self.preferredUnitSystemRaw = preferredUnitSystem?.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    func toProfile() -> UserComfortProfile {
        let sensitivity = TemperatureSensitivity(rawValue: temperatureSensitivityRaw) ?? .normal
        let activities = preferredActivitiesRaw.compactMap { ActivityType(rawValue: $0) }
        
        var quietHours: TimeWindow?
        if quietHoursEnabled {
            let calendar = Calendar.current
            let now = Date()
            let start = calendar.date(
                bySettingHour: quietHoursStartHour,
                minute: quietHoursStartMinute,
                second: 0,
                of: now
            ) ?? now
            let end = calendar.date(
                bySettingHour: quietHoursEndHour,
                minute: quietHoursEndMinute,
                second: 0,
                of: now
            ) ?? now
            quietHours = TimeWindow(start: start, end: end, id: "quiet-hours")
        } else {
            quietHours = nil
        }
        
        return UserComfortProfile(
            temperatureSensitivity: sensitivity,
            preferredActivities: Set(activities),
            quietHours: quietHours,
            notificationPreferences: NotificationCategory.allCases.map {
                NotificationPreference(category: $0, isEnabled: true, preferredTime: nil)
            }
        )
    }

    func update(from profile: UserComfortProfile) {
        self.temperatureSensitivityRaw = profile.temperatureSensitivity.rawValue
        self.preferredActivitiesRaw = profile.preferredActivities.map { $0.rawValue }
        
        if let quietHours = profile.quietHours {
            let calendar = Calendar.current
            self.quietHoursStartHour = calendar.component(.hour, from: quietHours.start)
            self.quietHoursStartMinute = calendar.component(.minute, from: quietHours.start)
            self.quietHoursEndHour = calendar.component(.hour, from: quietHours.end)
            self.quietHoursEndMinute = calendar.component(.minute, from: quietHours.end)
            self.quietHoursEnabled = true
        } else {
            self.quietHoursEnabled = false
        }

        self.preferredLanguageRaw = profile.language.rawValue
        self.preferredAppearanceRaw = profile.appearance.rawValue
        self.preferredUnitSystemRaw = profile.unitSystem.rawValue
        self.updatedAt = Date()
    }
}
