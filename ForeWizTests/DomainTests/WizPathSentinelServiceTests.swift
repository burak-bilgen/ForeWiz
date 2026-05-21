import Foundation
import Testing
import CoreLocation
import WizPathKit
@testable import ForeWiz

@MainActor
@Suite("WizPathSentinelService Tests")
struct WizPathSentinelServiceTests {
    
    @Test("evaluateRouteChange returns suppressed when below threshold")
    func evaluateRouteChangeReturnsSuppressedWhenBelowThreshold() async throws {
        let service = WizPathSentinelService.shared
        
        let origin = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        let destination = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        let now = Date()
        
        let originalRoute = WizPathRoute(
            id: UUID(),
            origin: origin,
            destination: destination,
            travelMode: .car,
            departureTime: now,
            segments: [],
            totalDuration: 1800,
            totalDistance: 15000,
            polyline: nil
        )
        
        let updatedRoute = WizPathRoute(
            id: UUID(),
            origin: origin,
            destination: destination,
            travelMode: .car,
            departureTime: now,
            segments: [],
            totalDuration: 1900,
            totalDistance: 15000,
            polyline: nil
        )
        
        let weatherContext = WeatherContext(
            primaryHazard: nil,
            temperature: 25,
            conditions: [.clear],
            isExtreme: false
        )
        
        let decision = service.evaluateRouteChange(
            originalRoute: originalRoute,
            updatedRoute: updatedRoute,
            weatherContext: weatherContext
        )
        
        switch decision {
        case .suppressed(let reason):
            #expect(reason == .belowThreshold)
        case .trigger:
            Issue.record("Expected suppressed decision but got trigger")
        }
    }
    
    @Test("evaluateRouteChange triggers alert when delay exceeds 30 minutes")
    func evaluateRouteChangeTriggersAlertWhenDelayExceeds30Minutes() async throws {
        let service = WizPathSentinelService.shared
        
        let origin = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        let destination = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        let now = Date()
        
        let originalRoute = WizPathRoute(
            id: UUID(),
            origin: origin,
            destination: destination,
            travelMode: .car,
            departureTime: now,
            segments: [],
            totalDuration: 1800,
            totalDistance: 15000,
            polyline: nil
        )
        
        let updatedRoute = WizPathRoute(
            id: UUID(),
            origin: origin,
            destination: destination,
            travelMode: .car,
            departureTime: now,
            segments: [],
            totalDuration: 3600,
            totalDistance: 15000,
            polyline: nil
        )
        
        let weatherContext = WeatherContext(
            primaryHazard: .extremeHeat,
            temperature: 42,
            conditions: [.clear],
            isExtreme: true
        )
        
        let decision = service.evaluateRouteChange(
            originalRoute: originalRoute,
            updatedRoute: updatedRoute,
            weatherContext: weatherContext
        )
        
        switch decision {
        case .trigger(let alert):
            #expect(alert.severity == .high || alert.severity == .critical)
            #expect(alert.timeDifference == 1800)
        case .suppressed(let reason):
            Issue.record("Expected trigger decision but got suppressed: \(reason.description)")
        }
    }
    
    @Test("evaluateRouteChange triggers alert when percentage increase exceeds 40%")
    func evaluateRouteChangeTriggersAlertWhenPercentageIncreaseExceeds40Percent() async throws {
        let service = WizPathSentinelService.shared
        
        let origin = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        let destination = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        let now = Date()
        
        let originalRoute = WizPathRoute(
            id: UUID(),
            origin: origin,
            destination: destination,
            travelMode: .car,
            departureTime: now,
            segments: [],
            totalDuration: 3600,
            totalDistance: 30000,
            polyline: nil
        )
        
        let updatedRoute = WizPathRoute(
            id: UUID(),
            origin: origin,
            destination: destination,
            travelMode: .car,
            departureTime: now,
            segments: [],
            totalDuration: 5400,
            totalDistance: 30000,
            polyline: nil
        )
        
        let weatherContext = WeatherContext(
            primaryHazard: .severeStorm,
            temperature: 20,
            conditions: [.thunderstorm],
            isExtreme: false
        )
        
        let decision = service.evaluateRouteChange(
            originalRoute: originalRoute,
            updatedRoute: updatedRoute,
            weatherContext: weatherContext
        )
        
        switch decision {
        case .trigger(let alert):
            let percentageIncrease = alert.timeDifference / originalRoute.totalDuration
            #expect(percentageIncrease >= 0.40)
        case .suppressed(let reason):
            Issue.record("Expected trigger decision but got suppressed: \(reason.description)")
        }
    }
    
    @Test("SentinelAlert timeDifference calculation")
    func sentinelAlertTimeDifferenceCalculation() async throws {
        let alert = SentinelAlert(
            id: "test",
            signature: "test-sig",
            title: "Test Alert",
            body: "Test Body",
            severity: .high,
            originalDuration: 1800,
            updatedDuration: 3600,
            weatherContext: WeatherContext(
                primaryHazard: nil,
                temperature: 25,
                conditions: [],
                isExtreme: false
            ),
            timestamp: Date()
        )
        
        #expect(alert.timeDifference == 1800)
    }
    
    @Test("SuppressionReason descriptions")
    func suppressionReasonDescriptions() async throws {
        #expect(SuppressionReason.belowThreshold.description.contains("below"))
        #expect(SuppressionReason.rateLimited.description.contains("Rate limit"))
        #expect(SuppressionReason.cooldownActive.description.contains("Cooldown"))
        #expect(SuppressionReason.userDisabled.description.contains("disabled"))
    }
    
    @Test("WeatherContext isExtreme flag")
    func weatherContextIsExtremeFlag() async throws {
        let extremeContext = WeatherContext(
            primaryHazard: .extremeHeat,
            temperature: 45,
            conditions: [.clear],
            isExtreme: true
        )
        #expect(extremeContext.isExtreme == true)
        
        let normalContext = WeatherContext(
            primaryHazard: nil,
            temperature: 25,
            conditions: [.clear],
            isExtreme: false
        )
        #expect(normalContext.isExtreme == false)
    }
}
