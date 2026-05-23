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
    
    // MARK: - User Feedback / Learning
    /// Temperature offset in °C: positive means user runs hotter (feels warmer), negative means colder.
    /// Used by WeatherDecisionEngine to adjust scores. Range: -5 to +5.
    var temperatureOffset: Double
    /// Wind sensitivity multiplier: >1 means more sensitive to wind, <1 means less. Range: 0.5 to 2.0.
    var windSensitivityMultiplier: Double
    /// UV sensitivity: >1 means more sensitive to sun, <1 means less. Range: 0.5 to 2.0.
    var uvSensitivityMultiplier: Double
    /// Humidity sensitivity: >1 means more affected by humidity, <1 means less. Range: 0.5 to 2.0.
    var humiditySensitivityMultiplier: Double
    /// Preferred activity time: nil = flexible, or user's typical outdoor activity hours
    var preferredActivityStartHour: Int?
    var preferredActivityEndHour: Int?
    /// Whether the user has respiratory conditions (asthma, allergies) — affects AQI weighting
    var hasRespiratoryCondition: Bool
    /// Whether the user has joint sensitivity — affects joint pain weighting
    var hasJointSensitivity: Bool
    /// Simple thumbs feedback: tracks how many times user said "too hot" vs "too cold" vs "just right"
    var feedbackCounts: FeedbackCounts

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
        feedbackCounts: FeedbackCounts = FeedbackCounts()
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
    }

    static var `default`: UserComfortProfile {
        UserComfortProfile(
            notificationPreferences: NotificationCategory.allCases.map {
                NotificationPreference(category: $0, isEnabled: true, preferredTime: nil)
            }
        )
    }
    
    /// Record a piece of feedback and adjust learning parameters accordingly.
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
    
    /// Reset all learning data to defaults.
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

// MARK: - Feedback Types

/// Simple thumbs feedback counts to track user preferences over time.
struct FeedbackCounts: Codable, Equatable, Sendable {
    var tooHot: Int = 0
    var tooCold: Int = 0
    var justRight: Int = 0
    var windSensitive: Int = 0
    var tooSunny: Int = 0
    var tooHumid: Int = 0
    
    var total: Int { tooHot + tooCold + justRight + windSensitive + tooSunny + tooHumid }
}

/// Types of feedback a user can give about a weather recommendation.
enum UserWeatherFeedback: Equatable, Sendable, CustomStringConvertible {
    case tooHot
    case tooCold
    case justRight
    case windSensitive(Bool) // true = sensitive, false = not sensitive
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
