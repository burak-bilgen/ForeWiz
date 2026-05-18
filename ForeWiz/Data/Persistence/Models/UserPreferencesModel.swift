import Foundation
import SwiftData

@Model
final class UserPreferencesModel {
    @Attribute(.unique) var id: UUID
    var quietHoursStartHour: Int
    var quietHoursStartMinute: Int
    var quietHoursEndHour: Int
    var quietHoursEndMinute: Int
    var quietHoursEnabled: Bool
    var onboardingCompleted: Bool
    var preferredLanguageRaw: String?
    var preferredAppearanceRaw: String?
    var preferredUnitSystemRaw: String?
    var workoutHour: Int?
    var workoutMinute: Int?
    var notificationPreferencesData: Data?
    var maximumDailyNotifications: Int = 2
    var accentPaletteRaw: String?
    var savedLocationsData: Data?
    var selectedLocationID: String = "current-location"
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        quietHours: TimeWindow? = nil,
        onboardingCompleted: Bool = false,
        preferredLanguage: AppLanguage? = nil,
        preferredAppearance: AppAppearance? = nil
    ) {
        self.id = id
        
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
        self.accentPaletteRaw = AppAccentPalette.sky.rawValue
        self.selectedLocationID = SavedLocation.currentLocation.id
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    func toProfile() -> UserComfortProfile {
        let defaultProfile = UserComfortProfile.default
        let language = preferredLanguageRaw.flatMap(AppLanguage.init(rawValue:)) ?? .english
        let appearance = preferredAppearanceRaw.flatMap(AppAppearance.init(rawValue:)) ?? .system
        let accentPalette = accentPaletteRaw.flatMap(AppAccentPalette.init(rawValue:)) ?? .sky
        let notifications = decoded(
            [NotificationPreference].self,
            from: notificationPreferencesData
        ) ?? defaultProfile.notificationPreferences
        let locations = normalizedSavedLocations(
            decoded([SavedLocation].self, from: savedLocationsData) ?? defaultProfile.savedLocations
        )
        let selectedID = locations.contains(where: { $0.id == selectedLocationID })
            ? selectedLocationID
            : SavedLocation.currentLocation.id
        
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
            usualWorkoutTime: dateComponents(hour: workoutHour, minute: workoutMinute),
            quietHours: quietHours,
            notificationPreferences: normalizedNotificationPreferences(notifications),
            maximumDailyNotifications: maximumDailyNotifications,
            appearance: appearance,
            accentPalette: accentPalette,
            language: language,
            savedLocations: locations,
            selectedLocationID: selectedID
        )
    }

    func update(from profile: UserComfortProfile) {
        self.workoutHour = profile.usualWorkoutTime?.hour
        self.workoutMinute = profile.usualWorkoutTime?.minute
        
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
        self.notificationPreferencesData = encoded(profile.notificationPreferences)
        self.maximumDailyNotifications = profile.maximumDailyNotifications.clamped(to: 1...3)
        self.accentPaletteRaw = profile.accentPalette.rawValue
        self.savedLocationsData = encoded(normalizedSavedLocations(profile.savedLocations))
        self.selectedLocationID = profile.selectedLocationID
        self.updatedAt = Date()
    }

    private func dateComponents(hour: Int?, minute: Int?) -> DateComponents? {
        guard let hour else { return nil }
        return DateComponents(hour: hour, minute: minute ?? 0)
    }

    private func normalizedNotificationPreferences(
        _ preferences: [NotificationPreference]
    ) -> [NotificationPreference] {
        var byCategory: [NotificationCategory: NotificationPreference] = [:]
        preferences.forEach { byCategory[$0.category] = $0 }
        for category in NotificationCategory.allCases where byCategory[category] == nil {
            byCategory[category] = NotificationPreference(category: category, isEnabled: true, preferredTime: nil)
        }
        return NotificationCategory.allCases.compactMap { byCategory[$0] }
    }

    private func normalizedSavedLocations(_ locations: [SavedLocation]) -> [SavedLocation] {
        var result = locations
        if let index = result.firstIndex(where: { $0.id == SavedLocation.currentLocation.id }) {
            result[index] = SavedLocation.currentLocation
        } else {
            result.insert(.currentLocation, at: 0)
        }
        return result
    }

    private func encoded<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private func decoded<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
