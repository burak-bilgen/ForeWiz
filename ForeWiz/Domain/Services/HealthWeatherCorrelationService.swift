import Foundation

protocol HealthWeatherCorrelationService {
    func correlate(
        samples: [HealthSample],
        snapshot: WeatherSnapshot,
        profile: UserComfortProfile,
        baseAnalysis: HealthWeatherAnalysis,
        calendar: Calendar
    ) -> HealthWeatherAnalysis
}

struct DefaultHealthWeatherCorrelationService: HealthWeatherCorrelationService {

    private let minimumDaysForHighConfidence = 7

    func correlate(
        samples: [HealthSample],
        snapshot: WeatherSnapshot,
        profile: UserComfortProfile,
        baseAnalysis: HealthWeatherAnalysis,
        calendar: Calendar = .current
    ) -> HealthWeatherAnalysis {
        let grouped = Dictionary(grouping: samples, by: \.type)
        let uniqueDays = Set(samples.map { calendar.startOfDay(for: $0.date) })
        let confidence = determineConfidence(samples: samples, uniqueDays: uniqueDays)

        guard confidence != .none else {
            return baseAnalysis
        }

        var migraineRisk = baseAnalysis.migraineRisk
        var migraineLabel = baseAnalysis.migraineLabel
        var migraineAdvice = baseAnalysis.migraineAdvice
        var sleepQuality = baseAnalysis.sleepQuality
        var sleepLabel = baseAnalysis.sleepLabel
        var sleepAdvice = baseAnalysis.sleepAdvice
        var respiratoryIndex = baseAnalysis.respiratoryIndex
        var respiratoryLabel = baseAnalysis.respiratoryLabel
        var respiratoryAdvice = baseAnalysis.respiratoryAdvice
        var staminaIndex = baseAnalysis.staminaIndex
        var staminaLabel = baseAnalysis.staminaLabel
        var staminaAdvice = baseAnalysis.staminaAdvice

        let current = snapshot.current
        let daily = snapshot.daily
        let hourly = snapshot.hourly
        let aqi = snapshot.airQuality

        if let heartSamples = grouped[.heartRate] ?? grouped[.restingHeartRate] {
            correlateHeartRateWithHeat(
                heartSamples: heartSamples,
                current: current,
                hourly: hourly,
                migraineRisk: &migraineRisk,
                migraineLabel: &migraineLabel,
                migraineAdvice: &migraineAdvice,
                staminaIndex: &staminaIndex,
                staminaLabel: &staminaLabel,
                staminaAdvice: &staminaAdvice
            )
        }

        if let sleepSamples = grouped[.sleepHours] {
            correlateSleepWithTemperature(
                sleepSamples: sleepSamples,
                daily: daily,
                hourly: hourly,
                sleepQuality: &sleepQuality,
                sleepLabel: &sleepLabel,
                sleepAdvice: &sleepAdvice
            )
        }

        if let stepSamples = grouped[.steps] {
            correlateStepsWithWeather(
                stepSamples: stepSamples,
                daily: daily,
                staminaIndex: &staminaIndex,
                staminaLabel: &staminaLabel,
                staminaAdvice: &staminaAdvice
            )
        }

        if let respSamples = grouped[.respiratoryRate] {
            correlateRespiratoryWithAQI(
                respSamples: respSamples,
                aqi: aqi,
                respiratoryIndex: &respiratoryIndex,
                respiratoryLabel: &respiratoryLabel,
                respiratoryAdvice: &respiratoryAdvice
            )
        }

        if let uvSamples = grouped[.uvExposure] {
            correlateUVTrend(
                uvSamples: uvSamples,
                current: current,
                profile: profile,
                migraineRisk: &migraineRisk,
                migraineLabel: &migraineLabel,
                migraineAdvice: &migraineAdvice
            )
        }

        let adjustedOverall = recalculateOverallScore(
            migraineRisk: migraineRisk,
            sleepQuality: sleepQuality,
            jointPainIndex: baseAnalysis.jointPainIndex,
            respiratoryIndex: respiratoryIndex,
            staminaIndex: staminaIndex,
            airQualityIndex: baseAnalysis.airQualityIndex
        )

        return HealthWeatherAnalysis(
            migraineRisk: migraineRisk.clamped(to: 0...10),
            migraineLabel: migraineLabel,
            migraineAdvice: migraineAdvice,
            sleepQuality: sleepQuality.clamped(to: 0...10),
            sleepLabel: sleepLabel,
            sleepAdvice: sleepAdvice,
            jointPainIndex: baseAnalysis.jointPainIndex,
            jointPainLabel: baseAnalysis.jointPainLabel,
            jointPainAdvice: baseAnalysis.jointPainAdvice,
            respiratoryIndex: respiratoryIndex.clamped(to: 0...10),
            respiratoryLabel: respiratoryLabel,
            respiratoryAdvice: respiratoryAdvice,
            staminaIndex: staminaIndex.clamped(to: 0...10),
            staminaLabel: staminaLabel,
            staminaAdvice: staminaAdvice,
            airQualityIndex: baseAnalysis.airQualityIndex,
            airQualityLabel: baseAnalysis.airQualityLabel,
            airQualityAdvice: baseAnalysis.airQualityAdvice,
            airQualityCategory: baseAnalysis.airQualityCategory,
            pollenLevel: baseAnalysis.pollenLevel,
            overallHealthScore: adjustedOverall,
            healthSummary: baseAnalysis.healthSummary,
            confidence: confidence
        )
    }

    // MARK: - Confidence

    private func determineConfidence(samples: [HealthSample], uniqueDays: Set<Date>) -> CorrelationConfidence {
        guard !samples.isEmpty else { return .none }
        guard uniqueDays.count >= minimumDaysForHighConfidence else { return .low }

        let typesPresent = Set(samples.map(\.type))
        let allCorrelationTypes: Set<HealthSampleType> = [
            .heartRate, .restingHeartRate, .sleepHours, .steps, .respiratoryRate, .uvExposure
        ]
        let relevantTypes = typesPresent.intersection(allCorrelationTypes)

        if relevantTypes.count >= 4 {
            return .high
        }
        return .medium
    }

    // MARK: - Heart Rate + Temperature

    private func correlateHeartRateWithHeat(
        heartSamples: [HealthSample],
        current: CurrentWeatherPoint,
        hourly: [HourlyWeatherPoint],
        migraineRisk: inout Int,
        migraineLabel: inout String,
        migraineAdvice: inout String,
        staminaIndex: inout Int,
        staminaLabel: inout String,
        staminaAdvice: inout String
    ) {
        let avgHR = heartSamples.map(\.value).reduce(0, +) / Double(heartSamples.count)
        let highRestingHR = avgHR > 70

        let maxTemp = max(
            current.apparentTemperatureCelsius,
            hourly.map(\.apparentTemperatureCelsius).max() ?? current.apparentTemperatureCelsius
        )
        let highHeat = maxTemp > 30

        if highRestingHR && highHeat {
            staminaIndex = min(staminaIndex - 2, 10)
            staminaLabel = "Drained"
            staminaAdvice = "Your elevated heart rate combined with high heat can be draining. Stay indoors and hydrate."

            migraineRisk = min(migraineRisk + 1, 10)
            if migraineRisk >= 7 {
                migraineLabel = "High"
                migraineAdvice = "High resting heart rate in extreme heat increases migraine risk. Rest in a cool, dark room."
            }
        } else if highRestingHR && maxTemp > 26 {
            staminaIndex = max(staminaIndex - 1, 0)
            if staminaIndex <= 4 {
                staminaLabel = "Low"
                staminaAdvice = "Your heart rate is running high. Take it easy in the warm conditions."
            }
        }
    }

    // MARK: - Sleep + Night Temperature

    private func correlateSleepWithTemperature(
        sleepSamples: [HealthSample],
        daily: [DailyWeatherPoint],
        hourly: [HourlyWeatherPoint],
        sleepQuality: inout Int,
        sleepLabel: inout String,
        sleepAdvice: inout String
    ) {
        let avgSleep = sleepSamples.map(\.value).reduce(0, +) / Double(sleepSamples.count)

        let nightHourly = hourly.filter { h in
            let hour = Calendar.current.component(.hour, from: h.date)
            return hour >= 22 || hour <= 5
        }
        let nightTemp = nightHourly.map(\.temperatureCelsius).isEmpty
            ? daily.first?.lowTemperatureCelsius
            : nightHourly.map(\.temperatureCelsius).reduce(0, +) / Double(nightHourly.count)

        guard let effectiveNightTemp = nightTemp else { return }

        if avgSleep < 7 && effectiveNightTemp > 20 {
            sleepQuality = max(sleepQuality - 2, 0)
            sleepLabel = "Poor"
            sleepAdvice = "Light sleepers struggle in warm nights. Keep your bedroom cool for better rest."
        } else if avgSleep >= 7 && effectiveNightTemp >= 15 && effectiveNightTemp <= 18 {
            sleepQuality = min(sleepQuality + 1, 10)
            if sleepQuality >= 7 {
                sleepLabel = "Great"
                sleepAdvice = "Cool comfortable night ahead — you're likely to sleep well."
            }
        } else if avgSleep < 6 && effectiveNightTemp > 25 {
            sleepQuality = max(sleepQuality - 3, 0)
            sleepLabel = "Very Poor"
            sleepAdvice = "Hot nights severely impact sleep quality. Use a fan or air conditioning."
        }
    }

    // MARK: - Steps + Weather

    private func correlateStepsWithWeather(
        stepSamples: [HealthSample],
        daily: [DailyWeatherPoint],
        staminaIndex: inout Int,
        staminaLabel: inout String,
        staminaAdvice: inout String
    ) {
        let avgSteps = stepSamples.map(\.value).reduce(0, +) / Double(stepSamples.count)
        let lowSteps = avgSteps < 5000

        let todayHasGoodWeather = daily.first.map { day in
            day.highTemperatureCelsius >= 15 && day.highTemperatureCelsius <= 28 && (day.precipitationChance ?? 0) < 0.3
        } ?? false

        if lowSteps && todayHasGoodWeather {
            staminaIndex = max(staminaIndex - 1, 0)
            if staminaIndex <= 3 {
                staminaLabel = "Low"
                staminaAdvice = "You've been less active recently despite good weather. A short walk could help."
            }
        } else if !lowSteps && !todayHasGoodWeather {
            staminaIndex = min(staminaIndex + 1, 10)
            staminaLabel = "Fair"
            staminaAdvice = "You've been active regardless of weather — your fitness routine is solid."
        }
    }

    // MARK: - Respiratory Rate + Air Quality

    private func correlateRespiratoryWithAQI(
        respSamples: [HealthSample],
        aqi: AirQualityInfo?,
        respiratoryIndex: inout Int,
        respiratoryLabel: inout String,
        respiratoryAdvice: inout String
    ) {
        let avgRespRate = respSamples.map(\.value).reduce(0, +) / Double(respSamples.count)
        let highRespRate = avgRespRate > 16

        guard let airQuality = aqi else {
            if highRespRate {
                respiratoryIndex = min(respiratoryIndex + 1, 10)
                respiratoryLabel = "Elevated"
                respiratoryAdvice = "Your respiratory rate is above normal. Monitor your breathing today."
            }
            return
        }

        let poorAQI = airQuality.aqi > 100

        if highRespRate && poorAQI {
            respiratoryIndex = min(respiratoryIndex + 2, 10)
            respiratoryLabel = "Risky"
            respiratoryAdvice = "Your elevated breathing rate combined with poor air quality may cause discomfort. Limit outdoor exertion."
        } else if highRespRate && airQuality.aqi > 50 {
            respiratoryIndex = min(respiratoryIndex + 1, 10)
            if respiratoryIndex >= 5 {
                respiratoryLabel = "Moderate"
                respiratoryAdvice = "Consider reducing outdoor activity if you have respiratory sensitivity."
            }
        } else if avgRespRate > 18 && poorAQI {
            respiratoryIndex = min(respiratoryIndex + 3, 10)
            respiratoryLabel = "High Risk"
            respiratoryAdvice = "Significantly elevated respiratory rate with poor air quality. Avoid strenuous outdoor activity."
        }
    }

    // MARK: - UV Exposure Trend

    private func correlateUVTrend(
        uvSamples: [HealthSample],
        current: CurrentWeatherPoint,
        profile: UserComfortProfile,
        migraineRisk: inout Int,
        migraineLabel: inout String,
        migraineAdvice: inout String
    ) {
        let avgUV = uvSamples.map(\.value).reduce(0, +) / Double(uvSamples.count)
        let highPastExposure = avgUV > 5

        let todayUV = current.uvIndex ?? 0
        let highTodayUV = todayUV >= 6

        let sensitivity = profile.uvSensitivityMultiplier

        if highPastExposure && highTodayUV && sensitivity > 1.2 {
            migraineRisk = min(migraineRisk + 2, 10)
            if migraineRisk >= 7 {
                migraineLabel = "High"
                migraineAdvice = "Your UV exposure history suggests sensitivity. Today's strong sun may trigger headaches. Wear sunglasses and a hat."
            } else {
                migraineAdvice = "Past sun exposure combined with today's UV levels may cause discomfort. Stay shaded."
            }
        } else if highTodayUV && sensitivity > 1.0 {
            migraineRisk = min(migraineRisk + 1, 10)
            if migraineRisk >= 6 {
                migraineAdvice = "UV levels are high today. Protect your eyes and skin."
            }
        }
    }

    // MARK: - Overall Score

    private func recalculateOverallScore(
        migraineRisk: Int,
        sleepQuality: Int,
        jointPainIndex: Int,
        respiratoryIndex: Int,
        staminaIndex: Int,
        airQualityIndex: Int
    ) -> Int {
        let migraineInverted = 10 - migraineRisk
        let jointInverted = 10 - jointPainIndex
        let respiratoryInverted = 10 - respiratoryIndex
        let airQualityInverted = 10 - airQualityIndex
        let avg = Double(migraineInverted + sleepQuality + jointInverted + respiratoryInverted + staminaIndex + airQualityInverted) / 6.0
        return Int((avg / 10.0) * 100.0)
    }
}
