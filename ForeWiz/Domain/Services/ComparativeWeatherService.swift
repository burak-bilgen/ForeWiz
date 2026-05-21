import Foundation

/// Comparative weather intelligence - tells you how today compares to seasonal norms, yesterday, and weekly patterns.
struct ComparativeWeatherService {

    func analyze(
        snapshot: WeatherSnapshot,
        recommendation: DailyRecommendation,
        yesterdayHigh: Double? = nil,
        calendar: Calendar = .current
    ) -> ComparativeWeatherAnalysis {
        let daily = snapshot.daily

        // 1. Temperature anomaly (vs assumed "normal" baseline)
        let anomaly = calculateTemperatureAnomaly(daily: daily)

        // 2. Precipitation comparison
        let isUnusuallyRainy = checkUnusualRain(snapshot: snapshot)

        // 3. Day-over-day change
        let dayOverDay = calculateDayOverDayChange(daily: daily, yesterdayHigh: yesterdayHigh)

        // 4. Week pattern analysis
        let weekPattern = analyzeWeekPattern(daily: daily)

        // 5. Microclimate note
        let microclimateNote = generateMicroclimateNote(snapshot: snapshot)

        return ComparativeWeatherAnalysis(
            temperatureAnomalyCelsius: anomaly.anomaly,
            anomalyLabel: anomaly.label,
            anomalyDescription: anomaly.description,
            isUnusuallyRainy: isUnusuallyRainy.isUnusual,
            precipitationComparison: isUnusuallyRainy.description,
            dayOverDayChange: dayOverDay.text,
            dayOverDayDeltaCelsius: dayOverDay.delta,
            weekPattern: weekPattern.pattern,
            weekDescription: weekPattern.description,
            microclimateNote: microclimateNote
        )
    }

    // MARK: - Temperature Anomaly

    /// Estimates temperature anomaly by comparing to seasonal norms
    /// Uses rough seasonal baselines (can be enhanced with historical data)
    private func calculateTemperatureAnomaly(daily: [DailyWeatherPoint]) -> (anomaly: Double?, label: String, description: String) {
        guard let today = daily.first else {
            return (nil, L10n.text("comparative_no_data"), L10n.text("comparative_no_data_desc"))
        }

        let month = Calendar.current.component(.month, from: today.date)
        let seasonalNormal = seasonalBaseline(month: month)
        let anomaly = today.highTemperatureCelsius - seasonalNormal
        let roundedAnomaly = (anomaly * 2).rounded() / 2

        let (label, desc) = anomalyLabelAndDescription(anomaly: roundedAnomaly, month: month)

        return (roundedAnomaly, label, desc)
    }

    /// Rough seasonal temperature baselines for Mediterranean climate (Antalya region baseline)
    /// In production, this would use actual historical weather data API
    private func seasonalBaseline(month: Int) -> Double {
        switch month {
        case 1: return 15
        case 2: return 16
        case 3: return 19
        case 4: return 23
        case 5: return 28
        case 6: return 33
        case 7: return 36
        case 8: return 36
        case 9: return 32
        case 10: return 27
        case 11: return 21
        case 12: return 17
        default: return 25
        }
    }

    private func anomalyLabelAndDescription(anomaly: Double, month: Int) -> (String, String) {
        switch anomaly {
        case _ where anomaly >= 6:
            return (L10n.text("comparative_anomaly_extreme_hot"), L10n.text("comparative_anomaly_extreme_hot_desc"))
        case 3..<6:
            return (L10n.text("comparative_anomaly_hot"), L10n.text("comparative_anomaly_hot_desc"))
        case -3..<3:
            return (L10n.text("comparative_anomaly_normal"), L10n.text("comparative_anomaly_normal_desc"))
        case -6..<(-3):
            return (L10n.text("comparative_anomaly_cold"), L10n.text("comparative_anomaly_cold_desc"))
        default:
            return (L10n.text("comparative_anomaly_extreme_cold"), L10n.text("comparative_anomaly_extreme_cold_desc"))
        }
    }

    // MARK: - Precipitation Check

    private func checkUnusualRain(snapshot: WeatherSnapshot) -> (isUnusual: Bool, description: String) {
        let maxRainChance = snapshot.hourly.compactMap { $0.precipitationChance }.max() ?? 0

        if maxRainChance >= 0.8 {
            return (true, L10n.text("comparative_precip_heavy"))
        } else if maxRainChance >= 0.6 {
            return (true, L10n.text("comparative_precip_moderate"))
        } else if maxRainChance >= 0.3 {
            return (false, L10n.text("comparative_precip_light"))
        }
        return (false, L10n.text("comparative_precip_dry"))
    }

    // MARK: - Day Over Day

    private func calculateDayOverDayChange(
        daily: [DailyWeatherPoint],
        yesterdayHigh: Double?
    ) -> (text: String, delta: Double?) {
        guard daily.count >= 2 else {
            guard let today = daily.first, let yesterday = yesterdayHigh else {
                return (L10n.text("comparative_dod_no_data"), nil)
            }
            let delta = today.highTemperatureCelsius - yesterday
            return (dayOverDayText(delta: delta), delta)
        }

        let today = daily[0].highTemperatureCelsius
        let yesterday = daily[1].highTemperatureCelsius
        let delta = today - yesterday
        return (dayOverDayText(delta: delta), delta)
    }

    private func dayOverDayText(delta: Double) -> String {
        let rounded = Int(delta.rounded())
        if rounded > 0 {
            return String(format: L10n.text("comparative_dod_warmer"), abs(rounded))
        } else if rounded < 0 {
            return String(format: L10n.text("comparative_dod_cooler"), abs(rounded))
        }
        return L10n.text("comparative_dod_same")
    }

    // MARK: - Week Pattern

    private func analyzeWeekPattern(daily: [DailyWeatherPoint]) -> (pattern: ComparativeWeatherAnalysis.WeekWeatherPattern, description: String) {
        guard daily.count >= 3 else {
            return (.stable, L10n.text("comparative_pattern_limited"))
        }

        let temps = daily.map { $0.highTemperatureCelsius }

        // Check for heatwave (3+ days above 30°C)
        let consecutiveHot = measureConsecutiveHotDays(temps: temps)
        if consecutiveHot >= 3 {
            return (.heatwave, L10n.text("comparative_pattern_heatwave"))
        }

        // Check for cold snap (3+ days below 15°C)
        let consecutiveCold = measureConsecutiveColdDays(temps: temps)
        if consecutiveCold >= 3 {
            return (.coldSnap, L10n.text("comparative_pattern_coldsnap"))
        }

        // Check for warming trend
        let firstHalf = Array(temps.prefix(temps.count / 2))
        let secondHalf = Array(temps.suffix(temps.count / 2))
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

        if secondAvg - firstAvg >= 3 {
            return (.warmingUp, L10n.text("comparative_pattern_warming"))
        }
        if firstAvg - secondAvg >= 3 {
            return (.coolingDown, L10n.text("comparative_pattern_cooling"))
        }

        // Check for stormy spell
        let rainyDays = daily.filter { ($0.precipitationChance ?? 0) >= 0.5 }.count
        if rainyDays >= 3 {
            return (.stormySpell, L10n.text("comparative_pattern_stormy"))
        }
        if rainyDays >= 2 {
            return (.mixedBag, L10n.text("comparative_pattern_mixed"))
        }

        return (.stable, L10n.text("comparative_pattern_stable"))
    }

    private func measureConsecutiveHotDays(temps: [Double]) -> Int {
        var streak = 0
        for temp in temps {
            if temp >= 30 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private func measureConsecutiveColdDays(temps: [Double]) -> Int {
        var streak = 0
        for temp in temps {
            if temp <= 15 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Microclimate

    private func generateMicroclimateNote(snapshot: WeatherSnapshot) -> String? {
        // Simple microclimate detection: compare current location conditions
        // to typical patterns. Enhanced version would compare multiple locations.
        return nil
    }
}
