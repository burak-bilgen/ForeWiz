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
    var wardrobe: WardrobePreferences
    var savedLocations: [SavedLocation]
    var selectedLocationID: String
    var subscriptionTier: SubscriptionTier

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
        case wardrobe
        case savedLocations
        case selectedLocationID
        case subscriptionTier
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
        wardrobe: WardrobePreferences = .default,
        savedLocations: [SavedLocation] = [SavedLocation.currentLocation],
        selectedLocationID: String = "current-location",
        subscriptionTier: SubscriptionTier = .free
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
        self.wardrobe = wardrobe
        self.savedLocations = savedLocations
        self.selectedLocationID = selectedLocationID
        self.subscriptionTier = subscriptionTier
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

extension UserComfortProfile {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            temperatureSensitivity: try container.decodeIfPresent(
                TemperatureSensitivity.self,
                forKey: .temperatureSensitivity
            ) ?? .normal,
            preferredActivities: try container.decodeIfPresent(
                Set<ActivityType>.self,
                forKey: .preferredActivities
            ) ?? [.running, .walking, .goingOutside],
            wakeUpTime: try container.decodeIfPresent(DateComponents.self, forKey: .wakeUpTime),
            usualWorkoutTime: try container.decodeIfPresent(DateComponents.self, forKey: .usualWorkoutTime),
            quietHours: try container.decodeIfPresent(TimeWindow.self, forKey: .quietHours),
            notificationPreferences: try container.decodeIfPresent(
                [NotificationPreference].self,
                forKey: .notificationPreferences
            ) ?? NotificationCategory.allCases.map {
                NotificationPreference(category: $0, isEnabled: true, preferredTime: nil)
            },
            unitSystem: try container.decodeIfPresent(UnitSystem.self, forKey: .unitSystem) ?? .metric,
            maximumDailyNotifications: try container.decodeIfPresent(
                Int.self,
                forKey: .maximumDailyNotifications
            ) ?? 2,
            appearance: try container.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system,
            accentPalette: try container.decodeIfPresent(AppAccentPalette.self, forKey: .accentPalette) ?? .sky,
            language: try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system,
            wardrobe: try container.decodeIfPresent(WardrobePreferences.self, forKey: .wardrobe) ?? .default,
            savedLocations: try container.decodeIfPresent([SavedLocation].self, forKey: .savedLocations) ?? [SavedLocation.currentLocation],
            selectedLocationID: try container.decodeIfPresent(String.self, forKey: .selectedLocationID) ?? "current-location",
            subscriptionTier: try container.decodeIfPresent(SubscriptionTier.self, forKey: .subscriptionTier) ?? .free
        )
    }
}
