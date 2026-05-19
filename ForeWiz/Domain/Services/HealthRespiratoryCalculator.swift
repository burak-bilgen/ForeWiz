import Foundation

// MARK: - Respiratory Index Calculator

/// Calculates respiratory risk from weather triggers: cold air, humidity extremes, wind + dry conditions.
enum HealthRespiratoryCalculator {

    static func calculate(
        current: CurrentWeatherPoint,
        hourly: [HourlyWeatherPoint]
    ) -> (index: Int, label: String, advice: String) {
        var respScore = 0

        let temp = current.apparentTemperatureCelsius
        let humidity = current.humidity ?? 0.5
        let wind = current.windSpeedKph ?? 0

        // Cold air is a bronchoconstrictor
        if temp <= 5 {
            respScore += 3
        } else if temp <= 10 {
            respScore += 2
        }

        // High humidity + moderate warmth = mold/pollen proxy
        if humidity >= 0.75 && temp >= 18 && temp <= 28 {
            respScore += 3
        } else if humidity >= 0.65 && temp >= 20 {
            respScore += 2
        }

        // Wind + dry = airborne irritants
        if wind >= 25 && humidity <= 0.40 {
            respScore += 3
        } else if wind >= 20 && humidity <= 0.45 {
            respScore += 2
        }

        // Extreme dryness
        if humidity <= 0.25 {
            respScore += 2
        }

        let clampedResp = max(0, min(10, respScore))
        let (label, advice) = labelAndAdvice(for: clampedResp)

        return (clampedResp, label, advice)
    }

    // MARK: - Labels

    private static func labelAndAdvice(for index: Int) -> (String, String) {
        switch index {
        case 0...2:
            return (L10n.text("health_respiratory_low"), L10n.text("health_respiratory_low_advice"))
        case 3...5:
            return (L10n.text("health_respiratory_moderate"), L10n.text("health_respiratory_moderate_advice"))
        case 6...8:
            return (L10n.text("health_respiratory_high"), L10n.text("health_respiratory_high_advice"))
        default:
            return (L10n.text("health_respiratory_extreme"), L10n.text("health_respiratory_extreme_advice"))
        }
    }
}
