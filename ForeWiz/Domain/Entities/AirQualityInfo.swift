import Foundation

struct AirQualityInfo: Codable, Equatable, Sendable {

    let aqi: Int

    let pm25: Double?

    let pm10: Double?

    let ozone: Double?

    let pollenIndex: Int?

    let dominantPollutant: PollutantType?

    var category: AirQualityCategory {
        AirQualityCategory(aqi: aqi)
    }

    var healthRiskIndex: Int {
        switch aqi {
        case 0...50: return 0
        case 51...100: return 2
        case 101...150: return 4
        case 151...200: return 6
        case 201...300: return 8
        default: return 10
        }
    }

    var isUnhealthyForSensitiveGroups: Bool {
        aqi >= 101
    }

    var isUnhealthy: Bool {
        aqi >= 151
    }

    init(
        aqi: Int,
        pm25: Double? = nil,
        pm10: Double? = nil,
        ozone: Double? = nil,
        pollenIndex: Int? = nil,
        dominantPollutant: PollutantType? = nil
    ) {
        self.aqi = max(0, min(500, aqi))
        self.pm25 = pm25
        self.pm10 = pm10
        self.ozone = ozone
        self.pollenIndex = pollenIndex.map { max(0, min(10, $0)) }
        self.dominantPollutant = dominantPollutant
    }
}

enum AirQualityCategory: String, Codable, CaseIterable, Sendable {
    case good
    case moderate
    case unhealthyForSensitive
    case unhealthy
    case veryUnhealthy
    case hazardous

    init(aqi: Int) {
        switch aqi {
        case 0...50: self = .good
        case 51...100: self = .moderate
        case 101...150: self = .unhealthyForSensitive
        case 151...200: self = .unhealthy
        case 201...300: self = .veryUnhealthy
        default: self = .hazardous
        }
    }

    var localizedTitle: String {
        switch self {
        case .good: return L10n.text("aqi_good")
        case .moderate: return L10n.text("aqi_moderate")
        case .unhealthyForSensitive: return L10n.text("aqi_unhealthy_sensitive")
        case .unhealthy: return L10n.text("aqi_unhealthy")
        case .veryUnhealthy: return L10n.text("aqi_very_unhealthy")
        case .hazardous: return L10n.text("aqi_hazardous")
        }
    }

    var localizedAdvice: String {
        switch self {
        case .good: return L10n.text("aqi_advice_good")
        case .moderate: return L10n.text("aqi_advice_moderate")
        case .unhealthyForSensitive: return L10n.text("aqi_advice_sensitive")
        case .unhealthy: return L10n.text("aqi_advice_unhealthy")
        case .veryUnhealthy: return L10n.text("aqi_advice_very_unhealthy")
        case .hazardous: return L10n.text("aqi_advice_hazardous")
        }
    }

    var symbolName: String {
        switch self {
        case .good: return "leaf.fill"
        case .moderate: return "leaf"
        case .unhealthyForSensitive: return "exclamationmark.circle"
        case .unhealthy: return "exclamationmark.triangle.fill"
        case .veryUnhealthy: return "xmark.octagon.fill"
        case .hazardous: return "xmark.octagon.fill"
        }
    }

    var severityLevel: Int {
        switch self {
        case .good: return 0
        case .moderate: return 1
        case .unhealthyForSensitive: return 2
        case .unhealthy: return 3
        case .veryUnhealthy: return 4
        case .hazardous: return 5
        }
    }
}

enum PollutantType: String, Codable, CaseIterable, Sendable {
    case pm25 = "PM2.5"
    case pm10 = "PM10"
    case ozone = "O3"
    case nitrogenDioxide = "NO2"
    case sulfurDioxide = "SO2"
    case carbonMonoxide = "CO"
    case unknown

    var localizedName: String {
        switch self {
        case .pm25: return L10n.text("pollutant_pm25")
        case .pm10: return L10n.text("pollutant_pm10")
        case .ozone: return L10n.text("pollutant_ozone")
        case .nitrogenDioxide: return L10n.text("pollutant_nitrogen")
        case .sulfurDioxide: return L10n.text("pollutant_sulfur")
        case .carbonMonoxide: return L10n.text("pollutant_carbon")
        case .unknown: return L10n.text("pollutant_unknown")
        }
    }
}

enum PollenLevel: Int, Codable, Sendable {
    case none = 0
    case veryLow = 1
    case low = 2
    case moderate = 3
    case high = 4
    case veryHigh = 5
    case extreme = 6

    init(index: Int) {
        switch index {
        case 0...1: self = .none
        case 2...3: self = .low
        case 4...5: self = .moderate
        case 6...7: self = .high
        case 8...9: self = .veryHigh
        case 10: self = .extreme
        default: self = .none
        }
    }

    var localizedTitle: String {
        switch self {
        case .none: return L10n.text("pollen_none")
        case .veryLow: return L10n.text("pollen_very_low")
        case .low: return L10n.text("pollen_low")
        case .moderate: return L10n.text("pollen_moderate")
        case .high: return L10n.text("pollen_high")
        case .veryHigh: return L10n.text("pollen_very_high")
        case .extreme: return L10n.text("pollen_extreme")
        }
    }
}
