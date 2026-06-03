import Foundation

/// Smart narrative that tells a human-friendly "story" about today's weather.
/// Transforms raw weather data into a relatable, conversational experience.
struct WeatherNarrative: Codable, Equatable, Sendable {
    /// One-line headline like "A sizzling summer day with a cool afternoon breeze"
    let headline: String

    /// A personality archetype for today's weather (e.g., "energetic", "melancholic", "serene")
    let personality: WeatherPersonality

    /// A 1-2 sentence conversational story about today's weather
    let story: String

    /// A specific, actionable tip based on today's unique conditions
    let proTip: String

    /// A "mood" rating from 1-10 describing how pleasant the weather feels
    let moodScore: Int

    /// Short label for the mood (e.g., "Perfect", "Tough", "Okay")
    let moodLabel: String

    /// Emoji-like symbol name for the mood
    let moodSymbol: String

    enum WeatherPersonality: String, Codable, CaseIterable, Sendable {
        case energetic    // Bright, sunny, active
        case melancholic  // Rainy, gray, contemplative
        case serene       // Calm, mild, peaceful
        case dramatic     // Stormy, changing, intense
        case cozy         // Cold, snowy, stay-inside
        case refreshing   // Cool, crisp, clean-air
        case stubborn     // Mixed signals, unpredictable
        case lazy         // Hot, humid, slow-moving
        case adventurous  // Windy, exciting, dynamic
        case mysterious   // Foggy, hazy, dreamlike
    }
}

/// Confidence level for health-weather correlation data.
/// Indicates how much personal HealthKit data was available when computing the analysis.
enum CorrelationConfidence: String, Codable, CaseIterable, Sendable {
    /// Sufficient data (7+ days) across correlated metrics
    case high
    /// At least some data (7+ days) but not all metrics
    case medium
    /// Less than 7 days of data — estimates are tentative
    case low
    /// No HealthKit data available — purely weather-based
    case none
}

/// Health-weather correlation analysis.
/// Analyzes how weather conditions affect migraines, sleep, joints, respiratory health, and stamina.
struct HealthWeatherAnalysis: Codable, Equatable, Sendable {
    /// Migraine risk index (0=none, 10=extreme)
    let migraineRisk: Int
    let migraineLabel: String
    let migraineAdvice: String

    /// Sleep quality forecast for tonight (0=terrible, 10=perfect)
    let sleepQuality: Int
    let sleepLabel: String
    let sleepAdvice: String

    /// Joint pain discomfort index (0=none, 10=severe)
    let jointPainIndex: Int
    let jointPainLabel: String
    let jointPainAdvice: String

    /// Respiratory/asthma comfort index (0=perfect, 10=risky)
    let respiratoryIndex: Int
    let respiratoryLabel: String
    let respiratoryAdvice: String

    /// Outdoor stamina/energy index - how much energy you'll have outside (0=exhausted, 10=energized)
    let staminaIndex: Int
    let staminaLabel: String
    let staminaAdvice: String

    /// Air Quality Index (0=pristine, 10=hazardous)
    let airQualityIndex: Int
    let airQualityLabel: String
    let airQualityAdvice: String
    let airQualityCategory: AirQualityCategory
    /// Pollen level (0=none, 6=extreme), nil if unavailable
    let pollenLevel: Int?

    /// Overall health comfort score (0-100)
    let overallHealthScore: Int

    /// One-sentence summary of the health impact
    let healthSummary: String

    /// How much HealthKit data informed this analysis
    let confidence: CorrelationConfidence

    init(
        migraineRisk: Int,
        migraineLabel: String,
        migraineAdvice: String,
        sleepQuality: Int,
        sleepLabel: String,
        sleepAdvice: String,
        jointPainIndex: Int,
        jointPainLabel: String,
        jointPainAdvice: String,
        respiratoryIndex: Int,
        respiratoryLabel: String,
        respiratoryAdvice: String,
        staminaIndex: Int,
        staminaLabel: String,
        staminaAdvice: String,
        airQualityIndex: Int,
        airQualityLabel: String,
        airQualityAdvice: String,
        airQualityCategory: AirQualityCategory,
        pollenLevel: Int?,
        overallHealthScore: Int,
        healthSummary: String,
        confidence: CorrelationConfidence = .none
    ) {
        self.migraineRisk = migraineRisk
        self.migraineLabel = migraineLabel
        self.migraineAdvice = migraineAdvice
        self.sleepQuality = sleepQuality
        self.sleepLabel = sleepLabel
        self.sleepAdvice = sleepAdvice
        self.jointPainIndex = jointPainIndex
        self.jointPainLabel = jointPainLabel
        self.jointPainAdvice = jointPainAdvice
        self.respiratoryIndex = respiratoryIndex
        self.respiratoryLabel = respiratoryLabel
        self.respiratoryAdvice = respiratoryAdvice
        self.staminaIndex = staminaIndex
        self.staminaLabel = staminaLabel
        self.staminaAdvice = staminaAdvice
        self.airQualityIndex = airQualityIndex
        self.airQualityLabel = airQualityLabel
        self.airQualityAdvice = airQualityAdvice
        self.airQualityCategory = airQualityCategory
        self.pollenLevel = pollenLevel
        self.overallHealthScore = overallHealthScore
        self.healthSummary = healthSummary
        self.confidence = confidence
    }
}

/// Comparative analysis - how today's weather compares to seasonal norms, yesterday, and weekly patterns.
struct ComparativeWeatherAnalysis: Codable, Equatable, Sendable {
    /// Temperature anomaly (how many degrees different from typical)
    let temperatureAnomalyCelsius: Double?
    let anomalyLabel: String
    let anomalyDescription: String

    /// Whether today has unusually high precipitation
    let isUnusuallyRainy: Bool
    let precipitationComparison: String

    /// Whether today is significantly hotter/colder than yesterday
    let dayOverDayChange: String
    let dayOverDayDeltaCelsius: Double?

    /// Weather pattern description for the week
    let weekPattern: WeekWeatherPattern
    let weekDescription: String

    /// Microclimate insights if multiple locations in area
    let microclimateNote: String?

    enum WeekWeatherPattern: String, Codable, CaseIterable, Sendable {
        case stable          // Consistent weather throughout
        case warmingUp       // Getting progressively warmer
        case coolingDown     // Getting progressively cooler
        case stormySpell     // Multiple days of storms/rain
        case mixedBag        // Different conditions each day
        case heatwave        // Extended period of heat
        case coldSnap        // Extended period of cold
    }
}

/// A comprehensive daily briefing that combines narrative, health, and comparative analyses into a single view.
struct DailyWeatherBriefing: Codable, Equatable, Sendable {
    let narrative: WeatherNarrative
    let health: HealthWeatherAnalysis
    let comparative: ComparativeWeatherAnalysis

    /// The single most important thing to know about today
    let keyTakeaway: String

    /// Three prioritized actionable items for today
    let actionItems: [WeatherActionItem]

    /// Generated at timestamp
    let generatedAt: Date
}

struct WeatherActionItem: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let priority: Int  // 1 = highest
    let icon: String
    let title: String
    let description: String
    let category: ActionCategory

    enum ActionCategory: String, Codable, Sendable {
        case timing     // "Best time to go outside is 2-4 PM"
        case health     // "Stay hydrated - high heat today"
        case outfit     // "Grab a light jacket"
        case safety     // "Avoid being outside during the storm"
        case lifestyle  // "Great day for laundry - low humidity"
    }
}
