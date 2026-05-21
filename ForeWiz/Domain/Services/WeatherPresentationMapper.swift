import Foundation

/// Single source of truth for weather-to-presentation mapping.
///
/// Consolidates duplicate `conditionText`, `symbolName`, temperature formatting,
/// and daily scoring logic that was previously scattered across:
/// - `HomeViewStateFactory`
/// - `DefaultLoadHomeRecommendationUseCase` (widget caching)
///
/// Use this mapper everywhere weather data needs to be transformed for display.
struct WeatherPresentationMapper {

    // MARK: - Condition

    /// Returns a localized display string for the given weather condition code.
    func conditionText(for conditionCode: String?) -> String {
        let condition = conditionCode?.lowercased() ?? ""

        switch true {
        case condition.contains("thunder"), condition.contains("storm"):
            return L10n.text("weather_storm")
        case condition.contains("rain"), condition.contains("drizzle"):
            return L10n.text("weather_rain")
        case condition.contains("snow"), condition.contains("sleet"):
            return L10n.text("weather_snow")
        case condition.contains("cloud"):
            return L10n.text("weather_cloudy")
        case condition.contains("fog"), condition.contains("haze"):
            return L10n.text("weather_foggy")
        case condition.contains("clear"), condition.contains("sun"):
            return L10n.text("weather_clear")
        default:
            return L10n.text("weather_current")
        }
    }

    /// Returns an SF Symbol name for the given weather condition code and daylight status.
    func symbolName(for conditionCode: String?, isDaylight: Bool?) -> String {
        let condition = conditionCode?.lowercased() ?? ""

        switch true {
        case condition.contains("thunder"), condition.contains("storm"):
            return "cloud.bolt.rain.fill"
        case condition.contains("rain"), condition.contains("drizzle"):
            return "cloud.rain.fill"
        case condition.contains("snow"), condition.contains("sleet"):
            return "cloud.snow.fill"
        case condition.contains("cloud"):
            return isDaylight == false ? "cloud.moon.fill" : "cloud.sun.fill"
        case condition.contains("fog"), condition.contains("haze"):
            return "cloud.fog.fill"
        default:
            return isDaylight == false ? "moon.stars.fill" : "sun.max.fill"
        }
    }

    // MARK: - Temperature

    /// Formats a Celsius temperature value as a localized display string.
    func temperatureText(_ celsius: Double, unitSystem: UnitSystem) -> String {
        let value: Double
        let suffix: String

        switch unitSystem {
        case .metric:
            value = celsius
            suffix = L10n.text("unit_degree")
        case .imperial:
            value = (celsius * 9 / 5) + 32
            suffix = "°F"
        }

        return String(format: "%.0f", value) + suffix
    }

    /// Converts a Celsius temperature to the value in the target unit system (for numeric display).
    func temperatureValue(_ celsius: Double, unitSystem: UnitSystem) -> Double {
        switch unitSystem {
        case .metric: return celsius
        case .imperial: return (celsius * 9 / 5) + 32
        }
    }

    // MARK: - Score

    /// Computes a daily outdoor score (0–100) from temperature and precipitation data.
    ///
    /// Uses a climate-aware algorithm: higher temperatures and tropical nights are
    /// penalised more aggressively to reflect long-term warming concerns.
    func dailyScore(highCelsius: Double, lowCelsius: Double, precipitationChance: Double?) -> Int {
        var score = 100.0

        let highTarget = 24.0
        let lowTarget = 16.0

        // High temp penalty - aşırı sıcak günler çok daha ağır cezalandırılır
        let highDeviation = abs(highCelsius - highTarget)
        if highCelsius > 32 {
            score -= highDeviation * 3.5
        } else if highCelsius > 28 {
            score -= highDeviation * 2.5
        } else {
            score -= highDeviation * 1.8
        }

        // Low temp penalty - tropikal geceler (>20°C low) skoru düşürür
        if lowCelsius > 20 {
            score -= (lowCelsius - 20) * 3.0
        } else {
            score -= abs(lowTarget - lowCelsius) * 1.5
        }

        if let precip = precipitationChance {
            score -= precip * 0.55
        }

        return Int(max(0, min(100, score)))
    }
}
