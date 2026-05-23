import Foundation

// MARK: - Air Quality Health Calculator

/// Calculates health risk from air quality: AQI, PM2.5, PM10, ozone, and pollen.
/// Provides localized labels and actionable advice for each risk level.
enum HealthAirQualityCalculator {

    static func calculate(
        airQuality: AirQualityInfo?
    ) -> (index: Int, advice: String, category: AirQualityCategory) {
        guard let aq = airQuality else {
            return (0, L10n.text("health_aqi_unavailable_advice"), .good)
        }

        let category = aq.category
        let healthIndex = aq.healthRiskIndex

        let advice: String

        switch category {
        case .good:
            advice = L10n.text("health_aqi_good_advice")

        case .moderate:
            advice = L10n.text("health_aqi_moderate_advice")

        case .unhealthyForSensitive:
            // Add pollen context if available
            if let pollen = aq.pollenIndex, pollen >= 4 {
                advice = String(format: L10n.text("health_aqi_sensitive_pollen"), aq.aqi, pollen)
            } else if let dominant = aq.dominantPollutant {
                advice = String(format: L10n.text("health_aqi_sensitive_pollutant"), aq.aqi, dominant.localizedName)
            } else {
                advice = String(format: L10n.text("health_aqi_sensitive_default"), aq.aqi)
            }

        case .unhealthy:
            if let dominant = aq.dominantPollutant {
                advice = String(format: L10n.text("health_aqi_unhealthy_pollutant"), aq.aqi, dominant.localizedName)
            } else {
                advice = String(format: L10n.text("health_aqi_unhealthy_default"), aq.aqi)
            }

        case .veryUnhealthy:
            advice = String(format: L10n.text("health_aqi_very_unhealthy_advice"), aq.aqi)

        case .hazardous:
            advice = L10n.text("health_aqi_hazardous_advice")
        }

        return (healthIndex, advice, category)
    }

    /// Generates a concise one-line summary of air quality conditions.
    static func summary(airQuality: AirQualityInfo?) -> String {
        guard let aq = airQuality else {
            return L10n.text("health_aqi_no_data")
        }

        let categoryLabel = aq.category.localizedTitle
        let pollenNote: String
        if let pollen = aq.pollenIndex, pollen >= 3 {
            pollenNote = String(format: L10n.text("health_aqi_pollen_note"), PollenLevel(index: pollen).localizedTitle)
        } else {
            pollenNote = ""
        }

        if pollenNote.isEmpty {
            return String(format: L10n.text("health_aqi_summary"), aq.aqi, categoryLabel)
        }
        return String(format: L10n.text("health_aqi_summary_pollen"), aq.aqi, categoryLabel, pollenNote)
    }
}
