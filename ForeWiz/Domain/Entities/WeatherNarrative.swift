import Foundation

struct WeatherNarrative: Codable, Equatable, Sendable {

    let headline: String

    let personality: WeatherPersonality

    let story: String

    let proTip: String

    let moodScore: Int

    let moodLabel: String

    let moodSymbol: String

    enum WeatherPersonality: String, Codable, CaseIterable, Sendable {
        case energetic
        case melancholic
        case serene
        case dramatic
        case cozy
        case refreshing
        case stubborn
        case lazy
        case adventurous
        case mysterious
    }
}

enum CorrelationConfidence: String, Codable, CaseIterable, Sendable {

    case high

    case medium

    case low

    case none
}

struct HealthWeatherAnalysis: Codable, Equatable, Sendable {

    let migraineRisk: Int
    let migraineLabel: String
    let migraineAdvice: String

    let sleepQuality: Int
    let sleepLabel: String
    let sleepAdvice: String

    let jointPainIndex: Int
    let jointPainLabel: String
    let jointPainAdvice: String

    let respiratoryIndex: Int
    let respiratoryLabel: String
    let respiratoryAdvice: String

    let staminaIndex: Int
    let staminaLabel: String
    let staminaAdvice: String

    let airQualityIndex: Int
    let airQualityLabel: String
    let airQualityAdvice: String
    let airQualityCategory: AirQualityCategory

    let pollenLevel: Int?

    let overallHealthScore: Int

    let healthSummary: String

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

struct ComparativeWeatherAnalysis: Codable, Equatable, Sendable {

    let temperatureAnomalyCelsius: Double?
    let anomalyLabel: String
    let anomalyDescription: String

    let isUnusuallyRainy: Bool
    let precipitationComparison: String

    let dayOverDayChange: String
    let dayOverDayDeltaCelsius: Double?

    let weekPattern: WeekWeatherPattern
    let weekDescription: String

    let microclimateNote: String?

    enum WeekWeatherPattern: String, Codable, CaseIterable, Sendable {
        case stable
        case warmingUp
        case coolingDown
        case stormySpell
        case mixedBag
        case heatwave
        case coldSnap
    }
}

struct DailyWeatherBriefing: Codable, Equatable, Sendable {
    let narrative: WeatherNarrative
    let health: HealthWeatherAnalysis
    let comparative: ComparativeWeatherAnalysis

    let keyTakeaway: String

    let actionItems: [WeatherActionItem]

    let generatedAt: Date
}

struct WeatherActionItem: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let priority: Int
    let icon: String
    let title: String
    let description: String
    let category: ActionCategory

    enum ActionCategory: String, Codable, Sendable {
        case timing
        case health
        case outfit
        case safety
        case lifestyle
    }
}
