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
    var weatherParticleIntensity: Double

    var temperatureOffset: Double

    var windSensitivityMultiplier: Double

    var uvSensitivityMultiplier: Double

    var humiditySensitivityMultiplier: Double

    var preferredActivityStartHour: Int?
    var preferredActivityEndHour: Int?

    var hasRespiratoryCondition: Bool

    var hasJointSensitivity: Bool

    var feedbackCounts: FeedbackCounts
    var homeLocation: SavedLocation?
    var workLocation: SavedLocation?

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
        weatherParticleIntensity: Double = 0.15,
        temperatureOffset: Double = 0,
        windSensitivityMultiplier: Double = 1.0,
        uvSensitivityMultiplier: Double = 1.0,
        humiditySensitivityMultiplier: Double = 1.0,
        preferredActivityStartHour: Int? = nil,
        preferredActivityEndHour: Int? = nil,
        hasRespiratoryCondition: Bool = false,
        hasJointSensitivity: Bool = false,
        feedbackCounts: FeedbackCounts = FeedbackCounts(),
        homeLocation: SavedLocation? = nil,
        workLocation: SavedLocation? = nil
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
        self.temperatureOffset = temperatureOffset.clamped(to: -5...5)
        self.windSensitivityMultiplier = windSensitivityMultiplier.clamped(to: 0.5...2.0)
        self.uvSensitivityMultiplier = uvSensitivityMultiplier.clamped(to: 0.5...2.0)
        self.humiditySensitivityMultiplier = humiditySensitivityMultiplier.clamped(to: 0.5...2.0)
        self.preferredActivityStartHour = preferredActivityStartHour
        self.preferredActivityEndHour = preferredActivityEndHour
        self.hasRespiratoryCondition = hasRespiratoryCondition
        self.hasJointSensitivity = hasJointSensitivity
        self.feedbackCounts = feedbackCounts
        self.homeLocation = homeLocation
        self.workLocation = workLocation
    }

    static var `default`: UserComfortProfile {
        UserComfortProfile(
            notificationPreferences: NotificationCategory.allCases.map {
                NotificationPreference(category: $0, isEnabled: true, preferredTime: nil)
            }
        )
    }

    mutating func recordFeedback(_ feedback: UserWeatherFeedback) {
        switch feedback {
        case .tooHot:
            feedbackCounts.tooHot += 1
            temperatureOffset = (temperatureOffset - 0.5).clamped(to: -5...5)
        case .tooCold:
            feedbackCounts.tooCold += 1
            temperatureOffset = (temperatureOffset + 0.5).clamped(to: -5...5)
        case .justRight:
            feedbackCounts.justRight += 1
            if temperatureOffset > 0 {
                temperatureOffset = (temperatureOffset - 0.3).clamped(to: -5...5)
            } else if temperatureOffset < 0 {
                temperatureOffset = (temperatureOffset + 0.3).clamped(to: -5...5)
            }
        case .windSensitive(true):
            feedbackCounts.windSensitive += 1
            windSensitivityMultiplier = (windSensitivityMultiplier + 0.15).clamped(to: 0.5...2.0)
        case .windSensitive(false):
            feedbackCounts.windSensitive += 1
            windSensitivityMultiplier = (windSensitivityMultiplier - 0.1).clamped(to: 0.5...2.0)
        case .tooSunny:
            feedbackCounts.tooSunny += 1
            uvSensitivityMultiplier = (uvSensitivityMultiplier + 0.15).clamped(to: 0.5...2.0)
        case .tooHumid:
            feedbackCounts.tooHumid += 1
            humiditySensitivityMultiplier = (humiditySensitivityMultiplier + 0.15).clamped(to: 0.5...2.0)
        case .humidityFine:
            feedbackCounts.tooHumid = max(0, feedbackCounts.tooHumid - 1)
            humiditySensitivityMultiplier = (humiditySensitivityMultiplier - 0.1).clamped(to: 0.5...2.0)
        }
    }

    mutating func resetLearning() {
        temperatureOffset = 0
        windSensitivityMultiplier = 1.0
        uvSensitivityMultiplier = 1.0
        humiditySensitivityMultiplier = 1.0
        preferredActivityStartHour = nil
        preferredActivityEndHour = nil
        hasRespiratoryCondition = false
        hasJointSensitivity = false
        feedbackCounts = FeedbackCounts()
    }
}

struct FeedbackCounts: Codable, Equatable, Sendable {
    var tooHot: Int = 0
    var tooCold: Int = 0
    var justRight: Int = 0
    var windSensitive: Int = 0
    var tooSunny: Int = 0
    var tooHumid: Int = 0

    var total: Int { tooHot + tooCold + justRight + windSensitive + tooSunny + tooHumid }
}

enum UserWeatherFeedback: Equatable, Sendable, CustomStringConvertible {
    case tooHot
    case tooCold
    case justRight
    case windSensitive(Bool)
    case tooSunny
    case tooHumid
    case humidityFine

    var description: String {
        switch self {
        case .tooHot: return "tooHot"
        case .tooCold: return "tooCold"
        case .justRight: return "justRight"
        case .windSensitive(true): return "windSensitive"
        case .windSensitive(false): return "notWindSensitive"
        case .tooSunny: return "tooSunny"
        case .tooHumid: return "tooHumid"
        case .humidityFine: return "humidityFine"
        }
    }
}
