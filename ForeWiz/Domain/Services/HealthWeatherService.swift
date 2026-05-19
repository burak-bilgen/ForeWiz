import Foundation

/// Health-Weather correlation intelligence.
/// Analyzes how weather conditions affect migraines, sleep, joints, respiratory health, and stamina.
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

        let overallScore = calculateOverallHealthScore(
            migraine: migraineRisk.risk,
            sleep: sleepQuality.quality,
            joint: jointPain.index,
            respiratory: respiratoryRisk.index,
            stamina: stamina.index
        )

        let summary = generateHealthSummary(
            migraineLabel: migraineRisk.label,
            sleepLabel: sleepQuality.label,
            jointLabel: jointPain.label,
            staminaLabel: stamina.label,
            overallScore: overallScore,
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
        stamina: Int
    ) -> Int {
        // Invert scores where higher = worse
        let migraineInverted = 10 - migraine
        let jointInverted = 10 - joint
        let respiratoryInverted = 10 - respiratory

        // All on 1-10 scale
        let avg = Double(migraineInverted + sleep + jointInverted + respiratoryInverted + stamina) / 5.0
        return Int((avg / 10.0) * 100.0)
    }

    private func generateHealthSummary(
        migraineLabel: String,
        sleepLabel: String,
        jointLabel: String,
        staminaLabel: String,
        overallScore: Int,
        decision: OutdoorDecision
    ) -> String {
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
