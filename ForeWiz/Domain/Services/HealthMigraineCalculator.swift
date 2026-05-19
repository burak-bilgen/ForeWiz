import Foundation

// MARK: - Migraine Risk Calculator

/// Calculates migraine risk from weather triggers: temperature swings, humidity, storm fronts, light sensitivity.
enum HealthMigraineCalculator {

    static func calculate(
        current: CurrentWeatherPoint,
        hourly: [HourlyWeatherPoint],
        calendar: Calendar = .current
    ) -> (risk: Int, label: String, advice: String) {
        var riskScore = 0

        // Temperature swing detection (major migraine trigger)
        let temps = hourly.map { $0.apparentTemperatureCelsius }
        if let maxTemp = temps.max(), let minTemp = temps.min() {
            let swing = maxTemp - minTemp
            if swing >= 12 {
                riskScore += 4
            } else if swing >= 8 {
                riskScore += 3
            } else if swing >= 5 {
                riskScore += 2
            }
        }

        // High humidity (barometric pressure correlate)
        if let humidity = current.humidity {
            if humidity >= 0.85 {
                riskScore += 3
            } else if humidity >= 0.70 {
                riskScore += 2
            } else if humidity >= 0.60 {
                riskScore += 1
            }
        }

        // Storm front (rapid pressure drop)
        let hasStormRisk = hourly.contains { $0.severeWeatherRisk != nil && $0.severeWeatherRisk! >= .medium }
        if hasStormRisk {
            riskScore += 3
        }

        // Bright/dark contrast (light sensitivity)
        let isDaylight = current.isDaylight ?? true
        if isDaylight && (current.uvIndex ?? 0) >= 6 {
            riskScore += 1
        }

        let clampedRisk = max(0, min(10, riskScore))
        let (label, advice) = labelAndAdvice(for: clampedRisk)

        return (clampedRisk, label, advice)
    }

    // MARK: - Labels

    private static func labelAndAdvice(for risk: Int) -> (String, String) {
        switch risk {
        case 0...2:
            return (L10n.text("health_migraine_low"), L10n.text("health_migraine_low_advice"))
        case 3...5:
            return (L10n.text("health_migraine_moderate"), L10n.text("health_migraine_moderate_advice"))
        case 6...8:
            return (L10n.text("health_migraine_high"), L10n.text("health_migraine_high_advice"))
        default:
            return (L10n.text("health_migraine_extreme"), L10n.text("health_migraine_extreme_advice"))
        }
    }
}
