import Foundation

// MARK: - Array Average Helper

extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}

// MARK: - Sleep Quality Calculator

/// Calculates sleep quality from weather factors: night temperature, humidity, wind noise, storm activity.
enum HealthSleepCalculator {

    static func calculate(
        current: CurrentWeatherPoint,
        hourly: [HourlyWeatherPoint],
        daily: [DailyWeatherPoint],
        calendar: Calendar = .current
    ) -> (quality: Int, label: String, advice: String) {
        var sleepScore = 10

        // Night temperature (ideal sleep: 16-20°C)
        let nightHours = hourly.filter {
            let h = calendar.component(.hour, from: $0.date)
            return (22...23).contains(h) || (0...5).contains(h)
        }

        if let avgNightTemp = nightHours.map({ $0.apparentTemperatureCelsius }).average {
            if avgNightTemp > 25 {
                sleepScore -= 4 // Tropical night - very disruptive
            } else if avgNightTemp > 22 {
                sleepScore -= 3
            } else if avgNightTemp > 20 {
                sleepScore -= 2
            } else if avgNightTemp < 10 {
                sleepScore -= 2
            } else if avgNightTemp < 14 {
                sleepScore -= 1
            }
        } else if let tonightTemp = current.apparentTemperatureCelsius as Double? {
            // Fallback to current temp if no night data
            if tonightTemp > 25 {
                sleepScore -= 3
            } else if tonightTemp > 22 {
                sleepScore -= 2
            } else if tonightTemp < 10 {
                sleepScore -= 2
            }
        }

        // Humidity impact on sleep
        if let humidity = current.humidity {
            if humidity >= 0.80 {
                sleepScore -= 2
            } else if humidity >= 0.65 {
                sleepScore -= 1
            }
        }

        // Wind noise (high wind = disturbed sleep)
        if let wind = current.windSpeedKph, wind >= 30 {
            sleepScore -= 2
        } else if let wind = current.windSpeedKph, wind >= 20 {
            sleepScore -= 1
        }

        // Storm night
        if hourly.contains(where: { point in
            guard let severeRisk = point.severeWeatherRisk else { return false }
            return severeRisk >= .medium
        }) {
            sleepScore -= 2
        }

        let clampedQuality = max(1, min(10, sleepScore))
        let (label, advice) = labelAndAdvice(for: clampedQuality)

        return (clampedQuality, label, advice)
    }

    // MARK: - Labels

    private static func labelAndAdvice(for quality: Int) -> (String, String) {
        switch quality {
        case 8...10:
            return (L10n.text("health_sleep_excellent"), L10n.text("health_sleep_excellent_advice"))
        case 6..<8:
            return (L10n.text("health_sleep_good"), L10n.text("health_sleep_good_advice"))
        case 4..<6:
            return (L10n.text("health_sleep_fair"), L10n.text("health_sleep_fair_advice"))
        default:
            return (L10n.text("health_sleep_poor"), L10n.text("health_sleep_poor_advice"))
        }
    }
}
