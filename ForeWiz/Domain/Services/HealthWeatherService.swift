import Foundation

/// Health-Weather correlation intelligence.
/// Analyzes how weather conditions affect migraines, sleep, joints, respiratory health, stamina, and air quality.
struct HealthWeatherService {

    /// Generates a complete health analysis from weather data.
    /// Each index is calculated by a dedicated calculator type.
    func analyzeHealth(
        snapshot: WeatherSnapshot,
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        calendar: Calendar = .current
    ) -> HealthWeatherAnalysis {
        let current = snapshot.current
        let hourly = snapshot.hourly
        let daily = snapshot.daily

        let migraineRisk = HealthMigraineCalculator.calculate(current: current, hourly: hourly, calendar: calendar)
        let sleepQuality = HealthSleepCalculator.calculate(current: current, hourly: hourly, daily: daily, calendar: calendar)
        let jointPain = HealthJointCalculator.calculate(current: current, hourly: hourly)
        let respiratoryRisk = HealthRespiratoryCalculator.calculate(current: current, hourly: hourly)
        let stamina = HealthStaminaCalculator.calculate(current: current, hourly: hourly)
        let airQuality = HealthAirQualityCalculator.calculate(airQuality: snapshot.airQuality)

        let overallScore = calculateOverallHealthScore(
            migraine: migraineRisk.risk,
            sleep: sleepQuality.quality,
            joint: jointPain.index,
            respiratory: respiratoryRisk.index,
            stamina: stamina.index,
            airQuality: airQuality.index
        )

        let summary = generateHealthSummary(
            overallScore: overallScore,
            airQuality: airQuality,
            migraineRisk: migraineRisk.risk,
            decision: recommendation.outdoorDecision
        )

        return HealthWeatherAnalysis(
            migraineRisk: migraineRisk.risk,
            migraineLabel: migraineRisk.label,
            migraineAdvice: migraineRisk.advice,
            sleepQuality: sleepQuality.quality,
            sleepLabel: sleepQuality.label,
            sleepAdvice: sleepQuality.advice,
            jointPainIndex: jointPain.index,
            jointPainLabel: jointPain.label,
            jointPainAdvice: jointPain.advice,
            respiratoryIndex: respiratoryRisk.index,
            respiratoryLabel: respiratoryRisk.label,
            respiratoryAdvice: respiratoryRisk.advice,
            staminaIndex: stamina.index,
            staminaLabel: stamina.label,
            staminaAdvice: stamina.advice,
            airQualityIndex: airQuality.index,
            airQualityLabel: airQuality.category.localizedTitle,
            airQualityAdvice: airQuality.advice,
            airQualityCategory: airQuality.category,
            pollenLevel: snapshot.airQuality?.pollenIndex,
            overallHealthScore: overallScore,
            healthSummary: summary
        )
    }

    // MARK: - Overall Score

    private func calculateOverallHealthScore(
        migraine: Int,
        sleep: Int,
        joint: Int,
        respiratory: Int,
        stamina: Int,
        airQuality: Int
    ) -> Int {
        // Invert scores where higher = worse
        let migraineInverted = 10 - migraine
        let jointInverted = 10 - joint
        let respiratoryInverted = 10 - respiratory
        let airQualityInverted = 10 - airQuality

        // All on 1-10 scale
        let avg = Double(migraineInverted + sleep + jointInverted + respiratoryInverted + stamina + airQualityInverted) / 6.0
        return Int((avg / 10.0) * 100.0)
    }

    private func generateHealthSummary(
        overallScore: Int,
        airQuality: (index: Int, advice: String, category: AirQualityCategory),
        migraineRisk: Int,
        decision: OutdoorDecision
    ) -> String {
        // If air quality is bad, mention it first
        if airQuality.index >= 6 {
            return String(format: L10n.text("health_summary_aqi_poor"), airQuality.category.localizedTitle)
        }

        // If migraine risk is high, prioritize that
        if migraineRisk >= 7 {
            return L10n.text("health_summary_migraine_risk")
        }

        switch overallScore {
        case 80...100:
            return L10n.text("health_summary_great")
        case 60..<80:
            return L10n.text("health_summary_good")
        case 40..<60:
            return L10n.text("health_summary_fair")
        default:
            return L10n.text("health_summary_poor")
        }
    }
}
