import Testing
import Foundation
@testable import ForeWiz

struct HealthWeatherServiceTests {
    private let service = HealthWeatherService()
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return cal
    }()

    // MARK: - Helpers

    private func makeHourlyPoints(
        temps: [Double] = [22, 23, 24, 25, 26, 27],
        humidities: [Double]? = nil,
        severeRisks: [RiskLevel?] = []
    ) -> [HourlyWeatherPoint] {
        let baseDate = Date()
        return temps.enumerated().map { i, temp in
            let date = baseDate.addingTimeInterval(Double(i) * 3600)
            let humidity = humidities?[safe: i] ?? 0.5
            let severeRisk = severeRisks[safe: i] ?? nil
            return HourlyWeatherPoint(
                date: date,
                temperatureCelsius: temp,
                apparentTemperatureCelsius: temp,
                humidity: humidity,
                windSpeedKph: 10,
                precipitationChance: 0,
                precipitationAmountMm: 0,
                uvIndex: 4,
                conditionCode: "clear",
                symbolName: "sun.max.fill",
                isDaylight: true,
                severeWeatherRisk: severeRisk
            )
        }
    }

    private func makeSnapshot(
        temp: Double = 22,
        humidity: Double? = 0.5,
        wind: Double? = 10,
        uv: Int? = 4,
        hourly: [HourlyWeatherPoint] = []
    ) -> WeatherSnapshot {
        let now = Date()
        let current = CurrentWeatherPoint(
            date: now,
            temperatureCelsius: temp,
            apparentTemperatureCelsius: temp,
            humidity: humidity,
            windSpeedKph: wind,
            precipitationChance: 0.05,
            precipitationAmountMm: 0,
            uvIndex: uv,
            conditionCode: "clear",
            symbolName: "sun.max.fill",
            isDaylight: true,
            severeWeatherRisk: nil
        )
        return WeatherSnapshot(
            location: LocationCoordinate(latitude: 36.9, longitude: 30.7),
            current: current,
            hourly: hourly,
            daily: [],
            fetchedAt: now,
            attribution: nil
        )
    }

    private func makeRecommendation(
        score: Int = 80,
        decision: OutdoorDecision = .good
    ) -> DailyRecommendation {
        DailyRecommendation(
            generatedAt: Date(),
            outdoorDecision: decision,
            outdoorScore: WeatherScore(rawValue: score),
            bestOutdoorWindow: nil,
            bestActivityWindows: [],
            avoidWindows: [],
            outfit: OutfitRecommendation(title: "title", items: [], accessories: [], warning: nil, detailedAdvice: nil),
            risks: [],
            summaryText: "Test",
            explanation: "\(score)/100",
            isTomorrowsRecommendation: false
        )
    }

    private func makeProfile() -> UserComfortProfile {
        UserComfortProfile(
            notificationPreferences: NotificationCategory.allCases.map {
                NotificationPreference(category: $0, isEnabled: true, preferredTime: nil)
            }
        )
    }

    // MARK: - Migraine Tests

    @Test func migraineRiskLowInStableConditions() {
        let hourly = makeHourlyPoints(temps: [22, 23, 23, 22, 23, 24])
        let snapshot = makeSnapshot(temp: 22, humidity: 0.4, hourly: hourly)
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.migraineRisk <= 3)
    }

    @Test func migraineRiskHighWithLargeTempSwing() {
        let hourly = makeHourlyPoints(temps: [15, 18, 22, 26, 28, 18])
        let snapshot = makeSnapshot(temp: 15, humidity: 0.8, hourly: hourly)
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.migraineRisk >= 4)
    }

    @Test func migraineRiskExtremeWithStorm() {
        let hourly = makeHourlyPoints(temps: [22, 24, 26, 25, 23, 21], severeRisks: [nil, nil, .high, .high, nil, nil])
        let snapshot = makeSnapshot(temp: 22, humidity: 0.85, hourly: hourly)
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.migraineRisk >= 6)
    }

    @Test func migraineAdviceNotEmpty() {
        let snapshot = makeSnapshot(temp: 22, hourly: makeHourlyPoints())
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.migraineAdvice.isEmpty == false)
    }

    // MARK: - Sleep Tests

    @Test func sleepExcellentInIdealNightTemp() {
        let hourly = makeHourlyPoints(temps: [18, 17, 16, 16, 15, 15])
        let snapshot = makeSnapshot(temp: 18, humidity: 0.4, hourly: hourly)
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.sleepQuality >= 7)
    }

    @Test func sleepPoorInHotNight() {
        let hourly = makeHourlyPoints(temps: [27, 27, 26, 26, 25, 25])
        let snapshot = makeSnapshot(temp: 27, humidity: 0.7, hourly: hourly)
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.sleepQuality <= 6)
    }

    @Test func sleepBoundaries() {
        let snapshot = makeSnapshot(temp: 18, hourly: makeHourlyPoints())
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.sleepQuality >= 1)
        #expect(analysis.sleepQuality <= 10)
    }

    // MARK: - Joint Pain Tests

    @Test func jointPainHighInColdAndHumid() {
        let snapshot = makeSnapshot(temp: 5, humidity: 0.85, hourly: makeHourlyPoints(temps: [5, 5, 5, 5, 5, 5]))
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.jointPainIndex >= 4)
    }

    @Test func jointPainLowInWarmDry() {
        let snapshot = makeSnapshot(temp: 25, humidity: 0.4, hourly: makeHourlyPoints(temps: [25, 26, 26, 25, 24, 24]))
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.jointPainIndex <= 3)
    }

    @Test func jointPainBoundaries() {
        let snapshot = makeSnapshot(temp: 22, hourly: makeHourlyPoints())
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.jointPainIndex >= 0)
        #expect(analysis.jointPainIndex <= 10)
    }

    // MARK: - Respiratory Tests

    @Test func respiratoryRiskyInColdWindy() {
        let snapshot = makeSnapshot(temp: 3, humidity: 0.3, wind: 30, hourly: makeHourlyPoints(temps: [3, 3, 2, 2, 1, 1]))
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.respiratoryIndex >= 4)
    }

    @Test func respiratoryGoodInMildConditions() {
        let snapshot = makeSnapshot(temp: 20, humidity: 0.5, wind: 8, hourly: makeHourlyPoints(temps: [20, 21, 22, 22, 21, 20]))
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.respiratoryIndex <= 3)
    }

    // MARK: - Stamina Tests

    @Test func staminaLowInExtremeHeat() {
        let snapshot = makeSnapshot(temp: 38, humidity: 0.6, hourly: makeHourlyPoints(temps: [38, 39, 40, 40, 39, 38]))
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.staminaIndex <= 5)
    }

    @Test func staminaHighInMildWeather() {
        let snapshot = makeSnapshot(temp: 22, humidity: 0.4, hourly: makeHourlyPoints(temps: [22, 23, 24, 24, 23, 22]))
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.staminaIndex >= 7)
    }

    @Test func staminaBoundaries() {
        let snapshot = makeSnapshot(temp: 22, hourly: makeHourlyPoints())
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.staminaIndex >= 1)
        #expect(analysis.staminaIndex <= 10)
    }

    // MARK: - Overall Score Tests

    @Test func overallHealthScoreInIdealConditions() {
        let hourly = makeHourlyPoints(temps: [22, 23, 23, 22, 22, 21])
        let snapshot = makeSnapshot(temp: 22, humidity: 0.4, hourly: hourly)
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.overallHealthScore >= 60)
        #expect(analysis.overallHealthScore <= 100)
    }

    @Test func overallHealthScoreRange() {
        let snapshot = makeSnapshot(temp: 22, hourly: makeHourlyPoints())
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.overallHealthScore >= 0)
        #expect(analysis.overallHealthScore <= 100)
    }

    @Test func healthSummaryNotEmpty() {
        let snapshot = makeSnapshot(temp: 22, hourly: makeHourlyPoints())
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.healthSummary.isEmpty == false)
    }

    // MARK: - All Fields Present

    @Test func allHealthFieldsPopulated() {
        let snapshot = makeSnapshot(temp: 22, hourly: makeHourlyPoints())
        let analysis = service.analyzeHealth(snapshot: snapshot, recommendation: makeRecommendation(), profile: makeProfile(), calendar: calendar)
        #expect(analysis.migraineLabel.isEmpty == false)
        #expect(analysis.migraineAdvice.isEmpty == false)
        #expect(analysis.sleepLabel.isEmpty == false)
        #expect(analysis.sleepAdvice.isEmpty == false)
        #expect(analysis.jointPainLabel.isEmpty == false)
        #expect(analysis.jointPainAdvice.isEmpty == false)
        #expect(analysis.respiratoryLabel.isEmpty == false)
        #expect(analysis.respiratoryAdvice.isEmpty == false)
        #expect(analysis.staminaLabel.isEmpty == false)
        #expect(analysis.staminaAdvice.isEmpty == false)
    }
}

// MARK: - Safe Array Extension for Tests

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
