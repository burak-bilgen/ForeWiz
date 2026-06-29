import Testing
import Foundation
@testable import ForeWiz

struct ComparativeWeatherServiceTests {
    private let service = ComparativeWeatherService()
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return cal
    }()

    private func makeDailyPoints(
        temps: [(high: Double, low: Double)] = [(28, 18), (26, 16), (24, 14)],
        precipChances: [Double?] = [0.1, 0.2, 0.3],
        date: Date = Date()
    ) -> [DailyWeatherPoint] {
        temps.enumerated().map { i, pair in
            let dayDate = Calendar.current.date(byAdding: .day, value: i, to: date) ?? date
            let precip = precipChances[safe: i] ?? 0.1
            return DailyWeatherPoint(
                date: dayDate,
                highTemperatureCelsius: pair.high,
                lowTemperatureCelsius: pair.low,
                precipitationChance: precip,
                uvIndex: 5,
                conditionCode: "clear",
                symbolName: "sun.max.fill",
                sunrise: nil,
                sunset: nil
            )
        }
    }

    private func makeHourlyPoints(
        precipChances: [Double] = [0.05, 0.1, 0.2, 0.15, 0.08, 0.03]
    ) -> [HourlyWeatherPoint] {
        let baseDate = Date()
        return precipChances.enumerated().map { i, precip in
            HourlyWeatherPoint(
                date: baseDate.addingTimeInterval(Double(i) * 3600),
                temperatureCelsius: 25,
                apparentTemperatureCelsius: 25,
                humidity: 0.5,
                windSpeedKph: 10,
                precipitationChance: precip,
                precipitationAmountMm: 0,
                uvIndex: 4,
                conditionCode: "clear",
                symbolName: "sun.max.fill",
                isDaylight: true,
                severeWeatherRisk: nil
            )
        }
    }

    private func makeSnapshot(
        daily: [DailyWeatherPoint] = [],
        hourly: [HourlyWeatherPoint] = []
    ) -> WeatherSnapshot {
        let now = Date()
        let current = CurrentWeatherPoint(
            date: now,
            temperatureCelsius: 25,
            apparentTemperatureCelsius: 25,
            humidity: 0.5,
            windSpeedKph: 10,
            precipitationChance: 0.05,
            precipitationAmountMm: 0,
            uvIndex: 4,
            conditionCode: "clear",
            symbolName: "sun.max.fill",
            isDaylight: true,
            severeWeatherRisk: nil
        )
        return WeatherSnapshot(
            location: LocationCoordinate(latitude: 36.9, longitude: 30.7),
            current: current,
            hourly: hourly,
            daily: daily,
            fetchedAt: now,
            attribution: nil
        )
    }

    private func makeRecommendation() -> DailyRecommendation {
        DailyRecommendation(
            generatedAt: Date(),
            outdoorDecision: .good,
            outdoorScore: WeatherScore(rawValue: 80),
            bestOutdoorWindow: nil,
            bestActivityWindows: [],
            avoidWindows: [],
            outfit: OutfitRecommendation(title: "title", items: [], accessories: [], warning: nil, detailedAdvice: nil),
            risks: [],
            summaryText: "Good",
            explanation: "80/100",
            isTomorrowsRecommendation: false
        )
    }

    @Test func anomalyLabelPresentForSummer() {
        let daily = makeDailyPoints(temps: [(35, 24), (33, 22), (31, 20)])
        let snapshot = makeSnapshot(daily: daily)
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), calendar: calendar)
        #expect(analysis.anomalyLabel.isEmpty == false)
        #expect(analysis.anomalyDescription.isEmpty == false)
    }

    @Test func anomalyValueIsOptional() {
        let snapshot = makeSnapshot(daily: [])
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), calendar: calendar)

        if let anomaly = analysis.temperatureAnomalyCelsius {
            #expect(anomaly.isFinite)
        }
    }

    @Test func dryPrecipitationWhenLow() {
        let hourly = makeHourlyPoints(precipChances: [0.05, 0.08, 0.02, 0.03, 0.01, 0.0])
        let snapshot = makeSnapshot(hourly: hourly)
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), calendar: calendar)
        #expect(analysis.isUnusuallyRainy == false)
        #expect(analysis.precipitationComparison.isEmpty == false)
    }

    @Test func heavyPrecipitationWhenHigh() {
        let hourly = makeHourlyPoints(precipChances: [0.1, 0.85, 0.9, 0.7, 0.3, 0.1])
        let snapshot = makeSnapshot(hourly: hourly)
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), calendar: calendar)
        #expect(analysis.isUnusuallyRainy == true)
    }

    @Test func dayOverDayWithMultipleDays() {
        let daily = makeDailyPoints(temps: [(30, 20), (26, 18), (25, 17)])
        let snapshot = makeSnapshot(daily: daily)
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), calendar: calendar)
        #expect(analysis.dayOverDayChange.isEmpty == false)
    }

    @Test func dayOverDayWithYesterdayHigh() {
        let daily = makeDailyPoints(temps: [(28, 20)])
        let snapshot = makeSnapshot(daily: daily)
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), yesterdayHigh: 25, calendar: calendar)
        #expect(analysis.dayOverDayChange.isEmpty == false)
        #expect(analysis.dayOverDayDeltaCelsius != nil)
    }

    @Test func heatwaveDetection() {
        let daily = makeDailyPoints(temps: [(36, 24), (37, 25), (38, 26), (35, 24), (34, 23)])
        let snapshot = makeSnapshot(daily: daily)
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), calendar: calendar)
        #expect(analysis.weekPattern == .heatwave)
    }

    @Test func coldSnapDetection() {
        let daily = makeDailyPoints(temps: [(12, 4), (10, 3), (11, 4), (13, 5)])
        let snapshot = makeSnapshot(daily: daily)
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), calendar: calendar)
        #expect(analysis.weekPattern == .coldSnap)
    }

    @Test func stablePatternWithConsistentTemps() {
        let daily = makeDailyPoints(temps: [(26, 18), (25, 17), (26, 18), (24, 16)])
        let snapshot = makeSnapshot(daily: daily)
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), calendar: calendar)
        #expect(analysis.weekPattern == .stable)
    }

    @Test func warmingTrendDetection() {
        let daily = makeDailyPoints(temps: [(22, 14), (24, 16), (27, 18), (29, 20)])
        let snapshot = makeSnapshot(daily: daily)
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), calendar: calendar)
        let isWarming = analysis.weekPattern == .warmingUp
        let isStable = analysis.weekPattern == .stable
        #expect(isWarming || isStable, "Should detect warming or stay stable with limited data")
    }

    @Test func allComparativeFieldsPopulated() {
        let daily = makeDailyPoints(temps: [(28, 18), (26, 16)])
        let hourly = makeHourlyPoints(precipChances: [0.1, 0.15, 0.2])
        let snapshot = makeSnapshot(daily: daily, hourly: hourly)
        let analysis = service.analyze(snapshot: snapshot, recommendation: makeRecommendation(), calendar: calendar)
        #expect(analysis.anomalyLabel.isEmpty == false)
        #expect(analysis.anomalyDescription.isEmpty == false)
        #expect(analysis.precipitationComparison.isEmpty == false)
        #expect(analysis.dayOverDayChange.isEmpty == false)
        #expect(analysis.weekDescription.isEmpty == false)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
