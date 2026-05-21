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
                id: "risk-1",
                type: .storm,
                severity: .high,
                message: "Severe thunderstorm expected",
                window: TimeWindow(start: Date(), end: Date().addingTimeInterval(3600))
            )
        ]
        
        let alerts = service.makeAlerts(from: risks)
        
        #expect(alerts.count == 1)
        #expect(alerts[0].event == .severeThunderstorm)
        #expect(alerts[0].severity == .high)
    }
    
    @Test("makeAlerts creates no alerts for low severity risks")
    func makeAlertsCreatesNoAlertsForLowSeverityRisks() async throws {
        let service = SevereWeatherAlertService.shared
        
        let risks = [
            WeatherRisk(
                id: "risk-2",
                type: .storm,
                severity: .low,
                message: "Light rain expected",
                window: TimeWindow(start: Date(), end: Date().addingTimeInterval(3600))
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
                id: "risk-3",
                type: .uv,
                severity: .high,
                message: "High UV index",
                window: TimeWindow(start: Date(), end: Date().addingTimeInterval(3600))
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
                id: "risk-4",
                type: .humidity,
                severity: .high,
                message: "High humidity",
                window: TimeWindow(start: Date(), end: Date().addingTimeInterval(3600))
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
                id: "risk-5",
                type: .poorComfort,
                severity: .high,
                message: "Poor comfort level",
                window: TimeWindow(start: Date(), end: Date().addingTimeInterval(3600))
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
                id: "risk-6",
                type: .heat,
                severity: .extreme,
                message: "Extreme heat warning",
                window: TimeWindow(start: Date(), end: Date().addingTimeInterval(3600))
            )
        ]
        
        let alerts = service.makeAlerts(from: risks)
        
        #expect(alerts.count == 1)
        #expect(alerts[0].event == .extremeHeat)
    }
    
    @Test("makeAlerts creates cold alert for cold risk")
    func makeAlertsCreatesColdAlertForColdRisk() async throws {
        let service = SevereWeatherAlertService.shared
        
        let risks = [
            WeatherRisk(
                id: "risk-7",
                type: .cold,
                severity: .high,
                message: "Extreme cold warning",
                window: TimeWindow(start: Date(), end: Date().addingTimeInterval(3600))
            )
        ]
        
        let alerts = service.makeAlerts(from: risks)
        
        #expect(alerts.count == 1)
        #expect(alerts[0].event == .extremeCold)
    }
    
    @Test("makeAlerts creates wind alert for wind risk")
    func makeAlertsCreatesWindAlertForWindRisk() async throws {
        let service = SevereWeatherAlertService.shared
        
        let risks = [
            WeatherRisk(
                id: "risk-8",
                type: .wind,
                severity: .high,
                message: "High wind warning",
                window: TimeWindow(start: Date(), end: Date().addingTimeInterval(3600))
            )
        ]
        
        let alerts = service.makeAlerts(from: risks)
        
        #expect(alerts.count == 1)
        #expect(alerts[0].event == .highWind)
    }
    
    @Test("makeAlerts creates flash flood alert for rain risk")
    func makeAlertsCreatesFlashFloodAlertForRainRisk() async throws {
        let service = SevereWeatherAlertService.shared
        
        let risks = [
            WeatherRisk(
                id: "risk-9",
                type: .rain,
                severity: .high,
                message: "Heavy rain and flash flood",
                window: TimeWindow(start: Date(), end: Date().addingTimeInterval(3600))
            )
        ]
        
        let alerts = service.makeAlerts(from: risks)
        
        #expect(alerts.count == 1)
        #expect(alerts[0].event == .flashFlood)
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
                id: "risk-10",
                type: .storm,
                severity: .high,
                message: "Storm warning",
                window: TimeWindow(start: Date(), end: Date().addingTimeInterval(3600))
            )
        ]
        
        let alerts = service.makeAlerts(from: risks)
        
        #expect(alerts.count == 1)
        let alert = alerts[0]
        let expectedExpiry = alert.effective.addingTimeInterval(24 * 60 * 60)
        #expect(abs(alert.expires.timeIntervalSince(expectedExpiry)) < 10)
    }
}
