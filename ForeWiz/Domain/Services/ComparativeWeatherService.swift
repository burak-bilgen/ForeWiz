import Foundation

struct ComparativeWeatherService {

    func analyze(
        snapshot: WeatherSnapshot,
        recommendation: DailyRecommendation,
        yesterdayHigh: Double? = nil,
        calendar: Calendar = .current
    ) -> ComparativeWeatherAnalysis {
        let daily = snapshot.daily

        let anomaly = calculateTemperatureAnomaly(daily: daily)

        let isUnusuallyRainy = checkUnusualRain(snapshot: snapshot)

        let dayOverDay = calculateDayOverDayChange(daily: daily, yesterdayHigh: yesterdayHigh)

        let weekPattern = analyzeWeekPattern(daily: daily)

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

    private func analyzeWeekPattern(daily: [DailyWeatherPoint]) -> (pattern: ComparativeWeatherAnalysis.WeekWeatherPattern, description: String) {
        guard daily.count >= 3 else {
            return (.stable, L10n.text("comparative_pattern_limited"))
        }

        let temps = daily.map { $0.highTemperatureCelsius }

        let consecutiveHot = measureConsecutiveHotDays(temps: temps)
        if consecutiveHot >= 3 {
            return (.heatwave, L10n.text("comparative_pattern_heatwave"))
        }

        let consecutiveCold = measureConsecutiveColdDays(temps: temps)
        if consecutiveCold >= 3 {
            return (.coldSnap, L10n.text("comparative_pattern_coldsnap"))
        }

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

    private func generateMicroclimateNote(snapshot: WeatherSnapshot) -> String? {
        let current = snapshot.current
        let hourly = snapshot.hourly
        let lat = snapshot.location.latitude
        let temp = current.apparentTemperatureCelsius
        let humidity = current.humidity ?? 0.5
        let wind = current.windSpeedKph ?? 0
        let calendar = Calendar.current
        let month = calendar.component(.month, from: current.date)
        let hour = calendar.component(.hour, from: current.date)

        var notes: [String] = []

        let isCoastal: Bool = {

            let coastalLatBands: [(ClosedRange<Double>, String)] = [
                (36.0...37.5, "akdeniz"),
                (37.5...39.5, "ege"),
                (41.0...42.5, "karadeniz"),
                (40.0...41.5, "marmara")
            ]
            return coastalLatBands.contains { $0.0.contains(lat) }
        }()

        if isCoastal {
            if month >= 5 && month <= 10 {

                if hour >= 10 && hour <= 16 && wind >= 8 && wind <= 20 {
                    notes.append(L10n.text("microclimate_coastal_breeze_summer"))
                } else if temp >= 30 && humidity >= 0.65 {
                    notes.append(L10n.text("microclimate_coastal_humid_summer"))
                }
            } else if month >= 11 || month <= 3 {

                if temp >= 12 && temp <= 18 {
                    notes.append(L10n.text("microclimate_coastal_mild_winter"))
                }
            }
        }

        let isUrban: Bool = {
            let urbanAreas: [(ClosedRange<Double>, ClosedRange<Double>)] = [
                (40.8...41.3, 28.6...29.2),
                (39.7...40.1, 32.5...33.0),
                (38.2...38.6, 26.8...27.4),
                (36.7...37.2, 28.5...29.5),
                (36.8...37.2, 35.0...35.6),
                (40.1...40.4, 28.7...29.2),
            ]
            let lon = snapshot.location.longitude
            return urbanAreas.contains { $0.0.contains(lat) && $0.1.contains(lon) }
        }()

        if isUrban {

            if !(hour >= 6 && hour <= 20) && temp >= 22 {
                notes.append(L10n.text("microclimate_urban_heat_night"))
            } else if temp >= 32 && hour >= 11 && hour <= 17 {
                notes.append(L10n.text("microclimate_urban_heat_day"))
            }
        }

        if !isCoastal {
            let seasonalExpectedTemp: Double = {
                switch month {
                case 6...8: return 32.0
                case 3...5: return 22.0
                case 9...11: return 24.0
                default: return 12.0
                }
            }()

            let diff = seasonalExpectedTemp - temp
            if diff >= 6 && !isUrban {
                notes.append(L10n.text("microclimate_elevation_cool"))
            } else if diff <= -6 && isUrban == false {
                notes.append(L10n.text("microclimate_inland_heat"))
            }
        }

        if month == 4 || month == 5 {

            let tempSwing = hourly.map { $0.apparentTemperatureCelsius }
            if let maxT = tempSwing.max(), let minT = tempSwing.min(), (maxT - minT) >= 10 {
                notes.append(L10n.text("microclimate_spring_transition"))
            }
        } else if month == 10 || month == 11 {

            if temp <= 15 && humidity >= 0.7 {
                notes.append(L10n.text("microclimate_fall_chill"))
            }
        }

        guard !notes.isEmpty else { return nil }
        return notes.joined(separator: " ")
    }
}
