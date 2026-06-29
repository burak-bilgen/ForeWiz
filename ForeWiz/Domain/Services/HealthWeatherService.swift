import Foundation

struct HealthWeatherService {
    private let healthRepository: HealthRepository?
    private let correlationService: HealthWeatherCorrelationService
    private let sampleFetchDays: Int = 14

    init(
        healthRepository: HealthRepository? = nil,
        correlationService: HealthWeatherCorrelationService = DefaultHealthWeatherCorrelationService()
    ) {
        self.healthRepository = healthRepository
        self.correlationService = correlationService
    }

    func analyzeHealth(
        snapshot: WeatherSnapshot,
        recommendation: DailyRecommendation,
        profile: UserComfortProfile,
        calendar: Calendar = .current
    ) async -> HealthWeatherAnalysis {
        let baseAnalysis = computeBaseAnalysis(
            snapshot: snapshot,
            recommendation: recommendation,
            profile: profile,
            calendar: calendar
        )

        guard let repository = healthRepository else {
            return baseAnalysis
        }

        do {
            let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(86399)
            let startDate = calendar.date(byAdding: .day, value: -sampleFetchDays, to: endDate) ?? endDate

            let samples = try await fetchHealthSamples(repository: repository, start: startDate, end: endDate)

            guard !samples.isEmpty else {
                return baseAnalysis
            }

            return correlationService.correlate(
                samples: samples,
                snapshot: snapshot,
                profile: profile,
                baseAnalysis: baseAnalysis,
                calendar: calendar
            )
        } catch {
            return baseAnalysis
        }
    }

    private func computeBaseAnalysis(
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

    private func fetchHealthSamples(
        repository: HealthRepository,
        start: Date,
        end: Date
    ) async throws -> [HealthSample] {
        async let heartSamples = try repository.readHeartRateSamples(start: start, end: end)
        async let sleepSamples = try repository.readSleepSamples(start: start, end: end)
        async let steps = try repository.readStepCount(start: start, end: end)
        async let respSamples = try repository.readRespiratoryRate(start: start, end: end)
        async let uvSamples = try repository.readUVExposure(start: start, end: end)
        async let restingHR = try repository.readRestingHeartRate(start: start, end: end)

        let (heart, sleep, stepCount, resp, uv, resting) = try await (
            heartSamples, sleepSamples, steps, respSamples, uvSamples, restingHR
        )

        var samples: [HealthSample] = []
        samples.append(contentsOf: heart)
        samples.append(contentsOf: sleep)
        samples.append(contentsOf: resp)
        samples.append(contentsOf: uv)

        if stepCount > 0 {
            samples.append(HealthSample(type: .steps, value: stepCount, date: start))
        }

        if resting > 0 {
            samples.append(HealthSample(type: .restingHeartRate, value: resting, date: start))
        }

        return samples
    }

    private func calculateOverallHealthScore(
        migraine: Int,
        sleep: Int,
        joint: Int,
        respiratory: Int,
        stamina: Int,
        airQuality: Int
    ) -> Int {

        let migraineInverted = 10 - migraine
        let jointInverted = 10 - joint
        let respiratoryInverted = 10 - respiratory
        let airQualityInverted = 10 - airQuality

        let avg = Double(migraineInverted + sleep + jointInverted + respiratoryInverted + stamina + airQualityInverted) / 6.0
        return Int((avg / 10.0) * 100.0)
    }

    private func generateHealthSummary(
        overallScore: Int,
        airQuality: (index: Int, advice: String, category: AirQualityCategory),
        migraineRisk: Int,
        decision: OutdoorDecision
    ) -> String {

        if airQuality.index >= 6 {
            return String(format: L10n.text("health_summary_aqi_poor"), airQuality.category.localizedTitle)
        }

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
