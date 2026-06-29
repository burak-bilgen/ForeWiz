import Foundation
import Testing
@testable import ForeWiz

@Suite("SevereWeatherAlertService Tests")
struct SevereWeatherAlertServiceTests {

    @Test("makeAlerts creates alerts for high severity risks")
    func makeAlertsCreatesAlertsForHighSeverityRisks() async throws {
        let service = SevereWeatherAlertService.shared

        let risks = [
            WeatherRisk(
                type: .storm,
                severity: .high,
                title: "Severe Thunderstorm",
                message: "Severe thunderstorm expected"
            )
        ]

        let alerts = service.makeAlerts(from: risks)

        #expect(alerts.count == 1)
        #expect(alerts[0].event == SevereWeatherEvent.severeThunderstorm)
        #expect(alerts[0].severity == .high)
    }

    @Test("makeAlerts creates no alerts for low severity risks")
    func makeAlertsCreatesNoAlertsForLowSeverityRisks() async throws {
        let service = SevereWeatherAlertService.shared

        let risks = [
            WeatherRisk(
                type: .storm,
                severity: .low,
                title: "Light Rain",
                message: "Light rain expected"
            )
        ]

        let alerts = service.makeAlerts(from: risks)

        #expect(alerts.isEmpty)
    }

    @Test("makeAlerts creates no alerts for UV risk")
    func makeAlertsCreatesNoAlertsForUVRisk() async throws {
        let service = SevereWeatherAlertService.shared

        let risks = [
            WeatherRisk(
                type: .uv,
                severity: .high,
                title: "High UV",
                message: "High UV index"
            )
        ]

        let alerts = service.makeAlerts(from: risks)

        #expect(alerts.isEmpty)
    }

    @Test("makeAlerts creates no alerts for humidity risk")
    func makeAlertsCreatesNoAlertsForHumidityRisk() async throws {
        let service = SevereWeatherAlertService.shared

        let risks = [
            WeatherRisk(
                type: .humidity,
                severity: .high,
                title: "High Humidity",
                message: "High humidity"
            )
        ]

        let alerts = service.makeAlerts(from: risks)

        #expect(alerts.isEmpty)
    }

    @Test("makeAlerts creates no alerts for poorComfort risk")
    func makeAlertsCreatesNoAlertsForPoorComfortRisk() async throws {
        let service = SevereWeatherAlertService.shared

        let risks = [
            WeatherRisk(
                type: .poorComfort,
                severity: .high,
                title: "Poor Comfort",
                message: "Poor comfort level"
            )
        ]

        let alerts = service.makeAlerts(from: risks)

        #expect(alerts.isEmpty)
    }

    @Test("makeAlerts creates heat alert for extreme heat risk")
    func makeAlertsCreatesHeatAlertForExtremeHeatRisk() async throws {
        let service = SevereWeatherAlertService.shared

        let risks = [
            WeatherRisk(
                type: .heat,
                severity: .extreme,
                title: "Extreme Heat",
                message: "Extreme heat warning"
            )
        ]

        let alerts = service.makeAlerts(from: risks)

        #expect(alerts.count == 1)
        #expect(alerts[0].event == SevereWeatherEvent.extremeHeat)
    }

    @Test("makeAlerts creates cold alert for cold risk")
    func makeAlertsCreatesColdAlertForColdRisk() async throws {
        let service = SevereWeatherAlertService.shared

        let risks = [
            WeatherRisk(
                type: .cold,
                severity: .high,
                title: "Extreme Cold",
                message: "Extreme cold warning"
            )
        ]

        let alerts = service.makeAlerts(from: risks)

        #expect(alerts.count == 1)
        #expect(alerts[0].event == SevereWeatherEvent.extremeCold)
    }

    @Test("makeAlerts creates wind alert for wind risk")
    func makeAlertsCreatesWindAlertForWindRisk() async throws {
        let service = SevereWeatherAlertService.shared

        let risks = [
            WeatherRisk(
                type: .wind,
                severity: .high,
                title: "High Wind",
                message: "High wind warning"
            )
        ]

        let alerts = service.makeAlerts(from: risks)

        #expect(alerts.count == 1)
        #expect(alerts[0].event == SevereWeatherEvent.highWind)
    }

    @Test("makeAlerts creates flash flood alert for rain risk")
    func makeAlertsCreatesFlashFloodAlertForRainRisk() async throws {
        let service = SevereWeatherAlertService.shared

        let risks = [
            WeatherRisk(
                type: .rain,
                severity: .high,
                title: "Flash Flood",
                message: "Heavy rain and flash flood"
            )
        ]

        let alerts = service.makeAlerts(from: risks)

        #expect(alerts.count == 1)
        #expect(alerts[0].event == SevereWeatherEvent.flashFlood)
    }

    @Test("shouldNotify returns true for high severity alert")
    func shouldNotifyReturnsTrueForHighSeverityAlert() async throws {
        let service = SevereWeatherAlertService.shared

        let alert = SevereWeatherAlert(
            id: "alert-1",
            event: .severeThunderstorm,
            severity: .high,
            headline: "Severe Thunderstorm",
            description: "Test",
            instruction: "Test",
            effective: Date(),
            expires: Date().addingTimeInterval(3600),
            areas: []
        )

        #expect(service.shouldNotify(alert: alert) == true)
    }

    @Test("shouldNotify returns true for extreme severity alert")
    func shouldNotifyReturnsTrueForExtremeSeverityAlert() async throws {
        let service = SevereWeatherAlertService.shared

        let alert = SevereWeatherAlert(
            id: "alert-2",
            event: .severeThunderstorm,
            severity: .extreme,
            headline: "Severe Thunderstorm",
            description: "Test",
            instruction: "Test",
            effective: Date(),
            expires: Date().addingTimeInterval(3600),
            areas: []
        )

        #expect(service.shouldNotify(alert: alert) == true)
    }

    @Test("shouldNotify returns false for medium severity alert")
    func shouldNotifyReturnsFalseForMediumSeverityAlert() async throws {
        let service = SevereWeatherAlertService.shared

        let alert = SevereWeatherAlert(
            id: "alert-3",
            event: .denseFog,
            severity: .medium,
            headline: "Dense Fog",
            description: "Test",
            instruction: "Test",
            effective: Date(),
            expires: Date().addingTimeInterval(3600),
            areas: []
        )

        #expect(service.shouldNotify(alert: alert) == false)
    }

    @Test("SevereWeatherEvent priority scores")
    func severeWeatherEventPriorityScores() async throws {
        #expect(SevereWeatherEvent.tornado.priorityScore == 100)
        #expect(SevereWeatherEvent.flashFlood.priorityScore == 95)
        #expect(SevereWeatherEvent.blizzard.priorityScore == 90)
        #expect(SevereWeatherEvent.extremeHeat.priorityScore == 85)
        #expect(SevereWeatherEvent.severeThunderstorm.priorityScore == 80)
        #expect(SevereWeatherEvent.denseFog.priorityScore == 60)
    }

    @Test("SevereWeatherAlert expires is 24 hours after effective")
    func severeWeatherAlertExpiresIs24HoursAfterEffective() async throws {
        let service = SevereWeatherAlertService.shared

        let risks = [
            WeatherRisk(
                type: .storm,
                severity: .high,
                title: "Storm Warning",
                message: "Storm warning"
            )
        ]

        let alerts = service.makeAlerts(from: risks)

        #expect(alerts.count == 1)
        let alert = alerts[0]
        let expectedExpiry = alert.effective.addingTimeInterval(24 * 60 * 60)
        #expect(abs(alert.expires.timeIntervalSince(expectedExpiry)) < 10)
    }
}
