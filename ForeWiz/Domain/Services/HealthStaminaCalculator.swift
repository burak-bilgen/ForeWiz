import Foundation

// MARK: - Stamina Index Calculator

/// Calculates outdoor stamina drain from weather: heat + humidity is the biggest killer, cold and wind also drain energy.
enum HealthStaminaCalculator {

    static func calculate(
        current: CurrentWeatherPoint,
        hourly: [HourlyWeatherPoint]
    ) -> (index: Int, label: String, advice: String) {
        var staminaScore = 10

        let temp = current.apparentTemperatureCelsius
        let humidity = current.humidity ?? 0.5

        // Heat index effect on stamina
        if temp >= 35 {
            staminaScore -= 5
        } else if temp >= 30 {
            staminaScore -= 4
        } else if temp >= 27 {
            staminaScore -= 3
        } else if temp >= 24 {
            staminaScore -= 1
        }

        // Humidity amplifies heat effect
        if temp >= 24 && humidity >= 0.70 {
            staminaScore -= 2
        } else if temp >= 24 && humidity >= 0.55 {
            staminaScore -= 1
        }

        // Cold also drains energy
        if temp <= 0 {
            staminaScore -= 3
        } else if temp <= 5 {
            staminaScore -= 2
        } else if temp <= 10 {
            staminaScore -= 1
        }

        // Wind can be draining at extreme speeds
        if let wind = current.windSpeedKph, wind >= 40 {
            staminaScore -= 2
        } else if let wind = current.windSpeedKph, wind >= 30 {
            staminaScore -= 1
        }

        let clampedStamina = max(1, min(10, staminaScore))
        let (label, advice) = labelAndAdvice(for: clampedStamina)

        return (clampedStamina, label, advice)
    }

    // MARK: - Labels

    private static func labelAndAdvice(for index: Int) -> (String, String) {
        switch index {
        case 8...10:
            return (L10n.text("health_stamina_high"), L10n.text("health_stamina_high_advice"))
        case 6..<8:
            return (L10n.text("health_stamina_good"), L10n.text("health_stamina_good_advice"))
        case 4..<6:
            return (L10n.text("health_stamina_moderate"), L10n.text("health_stamina_moderate_advice"))
        default:
            return (L10n.text("health_stamina_low"), L10n.text("health_stamina_low_advice"))
        }
    }
}
