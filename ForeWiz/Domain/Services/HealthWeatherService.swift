import Foundation

/// Health-Weather correlation intelligence.
/// Apple Weather has ZERO health integration — this is a massive differentiator.
/// Analyzes how weather conditions affect: migraines, sleep, joints, respiratory, and stamina.
struct HealthWeatherService {

    /// Generates a complete health analysis from weather data.
    /// Each index is calculated from specific weather triggers known to affect health conditions.
    func analyzeHealth(
        snapshot: WeatherSnapshot,
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        calendar: Calendar = .current
    ) -> HealthWeatherAnalysis {
        let current = snapshot.current
        let hourly = snapshot.hourly
        let daily = snapshot.daily

        let migraineRisk = calculateMigraineRisk(current: current, hourly: hourly, calendar: calendar)
        let sleepQuality = calculateSleepQuality(current: current, hourly: hourly, daily: daily, calendar: calendar)
        let jointPain = calculateJointPainIndex(current: current, hourly: hourly)
        let respiratoryRisk = calculateRespiratoryIndex(current: current, hourly: hourly)
        let stamina = calculateStaminaIndex(current: current, hourly: hourly)

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

    // MARK: - Migraine Risk

    /// Migraines are triggered by: rapid pressure changes, temperature swings, high humidity, storm fronts.
    /// We approximate pressure changes through condition transitions and temperature volatility.
    private func calculateMigraineRisk(
        current: CurrentWeatherPoint,
        hourly: [HourlyWeatherPoint],
        calendar: Calendar
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
        let (label, advice) = migraineLabelAndAdvice(for: clampedRisk)

        return (clampedRisk, label, advice)
    }

    private func migraineLabelAndAdvice(for risk: Int) -> (String, String) {
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

    // MARK: - Sleep Quality

    /// Sleep is affected by: night temperature, humidity, wind noise, pressure stability.
    private func calculateSleepQuality(
        current: CurrentWeatherPoint,
        hourly: [HourlyWeatherPoint],
        daily: [DailyWeatherPoint],
        calendar: Calendar
    ) -> (quality: Int, label: String, advice: String) {
        var sleepScore = 10

        // Night temperature (ideal sleep: 16-20°C)
        let nightHours = hourly.filter {
            let h = calendar.component(.hour, from: $0.date)
            return (22...23).contains(h) || (0...5).contains(h)
        }

        if let avgNightTemp = nightHours.map({ $0.apparentTemperatureCelsius }).average {
            if avgNightTemp > 25 {
                sleepScore -= 4 // Tropical night — very disruptive
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
        if hourly.contains(where: { $0.severeWeatherRisk != nil && $0.severeWeatherRisk! >= .medium }) {
            sleepScore -= 2
        }

        let clampedQuality = max(1, min(10, sleepScore))
        let (label, advice) = sleepLabelAndAdvice(for: clampedQuality)

        return (clampedQuality, label, advice)
    }

    private func sleepLabelAndAdvice(for quality: Int) -> (String, String) {
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

    // MARK: - Joint Pain Index

    /// Joint pain is triggered by: cold + humidity combo, rapid temperature drops, storm fronts.
    private func calculateJointPainIndex(
        current: CurrentWeatherPoint,
        hourly: [HourlyWeatherPoint]
    ) -> (index: Int, label: String, advice: String) {
        var painScore = 0

        let temp = current.apparentTemperatureCelsius
        let humidity = current.humidity ?? 0.5

        // Cold + humidity = worst combo for joints
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

        // Rapid temperature drops (within 12 hours)
        let temps = hourly.prefix(12).map { $0.apparentTemperatureCelsius }
        if let first = temps.first, let last = temps.last {
            let drop = first - last
            if drop >= 8 {
                painScore += 2
            } else if drop >= 5 {
                painScore += 1
            }
        }

        // Storm front (pressure drop correlate)
        if hourly.contains(where: { $0.severeWeatherRisk != nil && $0.severeWeatherRisk! >= .low }) {
            painScore += 1
        }

        let clampedPain = max(0, min(10, painScore))
        let (label, advice) = jointLabelAndAdvice(for: clampedPain)

        return (clampedPain, label, advice)
    }

    private func jointLabelAndAdvice(for index: Int) -> (String, String) {
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

    // MARK: - Respiratory Index

    /// Respiratory issues triggered by: high wind + pollen, humidity extremes, cold air, poor air quality proxy.
    private func calculateRespiratoryIndex(
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
        let (label, advice) = respiratoryLabelAndAdvice(for: clampedResp)

        return (clampedResp, label, advice)
    }

    private func respiratoryLabelAndAdvice(for index: Int) -> (String, String) {
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

    // MARK: - Stamina Index

    /// Outdoor stamina: how weather drains your energy.
    /// Heat + humidity is the biggest stamina killer.
    private func calculateStaminaIndex(
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
        let (label, advice) = staminaLabelAndAdvice(for: clampedStamina)

        return (clampedStamina, label, advice)
    }

    private func staminaLabelAndAdvice(for index: Int) -> (String, String) {
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

// MARK: - Array Average Helper

private extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
