import Foundation

enum HealthJointCalculator {

    static func calculate(
        current: CurrentWeatherPoint,
        hourly: [HourlyWeatherPoint]
    ) -> (index: Int, label: String, advice: String) {
        var painScore = 0

        let temp = current.apparentTemperatureCelsius
        let humidity = current.humidity ?? 0.5

        if temp <= 10 && humidity >= 0.70 {
            painScore += 4
        } else if temp <= 10 {
            painScore += 3
        } else if temp <= 15 && humidity >= 0.70 {
            painScore += 3
        } else if temp <= 15 {
            painScore += 2
        } else if temp <= 20 && humidity >= 0.75 {
            painScore += 2
        }

        let temps = hourly.prefix(12).map { $0.apparentTemperatureCelsius }
        if let first = temps.first, let last = temps.last {
            let drop = first - last
            if drop >= 8 {
                painScore += 2
            } else if drop >= 5 {
                painScore += 1
            }
        }

        if hourly.contains(where: { point in
            guard let severeRisk = point.severeWeatherRisk else { return false }
            return severeRisk >= .low
        }) {
            painScore += 1
        }

        let clampedPain = max(0, min(10, painScore))
        let (label, advice) = labelAndAdvice(for: clampedPain)

        return (clampedPain, label, advice)
    }

    private static func labelAndAdvice(for index: Int) -> (String, String) {
        switch index {
        case 0...2:
            return (L10n.text("health_joint_low"), L10n.text("health_joint_low_advice"))
        case 3...5:
            return (L10n.text("health_joint_moderate"), L10n.text("health_joint_moderate_advice"))
        case 6...8:
            return (L10n.text("health_joint_high"), L10n.text("health_joint_high_advice"))
        default:
            return (L10n.text("health_joint_extreme"), L10n.text("health_joint_extreme_advice"))
        }
    }
}
