import Foundation
import CoreLocation
import WizPathKit
@testable import ForeWiz

// MARK: - Mock Weather Service
/// Simulates weather API responses for testing - both success and failure scenarios
final class MockWeatherService {
    
    // MARK: - Configuration
    enum MockScenario {
        case success(SegmentWeather)
        case failure(Error)
        case nilResponse
        case timeout
        case outOfRangeDate
    }
    
    var scenario: MockScenario = .success(
        SegmentWeather(
            condition: .clear,
            temperature: 25.0,
            precipitationChance: 0.0,
            windSpeed: 5.0,
            visibility: 10000,
            severity: .good
        )
    )
    
    var callCount = 0
    var lastCoordinate: CLLocationCoordinate2D?
    var lastTime: Date?
    var delay: TimeInterval = 0
    
    // MARK: - Weather Fetching (for testing route segment weather)
    func fetchWeather(coordinate: CLLocationCoordinate2D, time: Date) async throws -> SegmentWeather {
        callCount += 1
        lastCoordinate = coordinate
        lastTime = time
        
        // Simulate network delay if configured
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        switch scenario {
        case .success(let weather):
            return weather
            
        case .failure(let error):
            throw error
            
        case .nilResponse:
            // Return a weather with nil-like values that should trigger fallback
            return SegmentWeather(
                condition: .clear,
                temperature: 0,
                precipitationChance: 0,
                windSpeed: 0,
                visibility: 0,
                severity: .good
            )
            
        case .timeout:
            throw NSError(
                domain: "MockWeatherService",
                code: -1001,
                userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
            )
            
        case .outOfRangeDate:
            throw NSError(
                domain: "MockWeatherService",
                code: -1002,
                userInfo: [NSLocalizedDescriptionKey: "Date out of valid range"]
            )
        }
    }
    
    // MARK: - Helper Methods
    func simulateExtremeHeat() {
        scenario = .success(
            SegmentWeather(
                condition: .clear,
                temperature: 42.0,
                precipitationChance: 0.0,
                windSpeed: 10.0,
                visibility: 10000,
                severity: .severe
            )
        )
    }
    
    func simulateSevereStorm() {
        scenario = .success(
            SegmentWeather(
                condition: .thunderstorm,
                temperature: 18.0,
                precipitationChance: 0.9,
                windSpeed: 60.0,
                visibility: 2000,
                severity: .severe
            )
        )
    }
    
    func simulateNetworkFailure() {
        scenario = .failure(
            NSError(
                domain: "MockWeatherService",
                code: -1009,
                userInfo: [NSLocalizedDescriptionKey: "Network connection lost"]
            )
        )
    }
    
    func reset() {
        callCount = 0
        lastCoordinate = nil
        lastTime = nil
        delay = 0
        scenario = .success(
            SegmentWeather(
                condition: .clear,
                temperature: 25.0,
                precipitationChance: 0.0,
                windSpeed: 5.0,
                visibility: 10000,
                severity: .good
            )
        )
    }
}

// MARK: - Mock Routing Service
/// Simulates MapKit routing and ETA calculations
final class MockRoutingService {
    
    // MARK: - Configuration
    enum MockScenario {
        case success(eta: TimeInterval, distance: CLLocationDistance)
        case noRoute
        case extremelyLongRoute
        case invalidCoordinates
        case networkFailure
    }
    
    var scenario: MockScenario = .success(eta: 1800, distance: 15000) // 30 min, 15km
    var callCount = 0
    var lastOrigin: CLLocationCoordinate2D?
    var lastDestination: CLLocationCoordinate2D?
    var delay: TimeInterval = 0
    
    // MARK: - Routing Simulation
    func calculateRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D
    ) async throws -> (eta: TimeInterval, distance: CLLocationDistance, route: MockRoute) {
        callCount += 1
        lastOrigin = origin
        lastDestination = destination
        
        // Simulate delay
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        switch scenario {
        case .success(let eta, let distance):
            let mockRoute = MockRoute(
                eta: eta,
                distance: distance,
                polyline: MockPolyline(coordinates: [origin, destination])
            )
            return (eta, distance, mockRoute)
            
        case .noRoute:
            throw WizPathError.noRouteAvailable
            
        case .extremelyLongRoute:
            // Simulate a very long route (e.g., cross-country)
            let longETA: TimeInterval = 8 * 3600 // 8 hours
            let longDistance: CLLocationDistance = 500_000 // 500km
            let mockRoute = MockRoute(
                eta: longETA,
                distance: longDistance,
                polyline: MockPolyline(coordinates: [origin, destination])
            )
            return (longETA, longDistance, mockRoute)
            
        case .invalidCoordinates:
            throw WizPathError.invalidCoordinates
            
        case .networkFailure:
            throw WizPathError.networkFailure
        }
    }
    
    func calculateETA(for hour: Int) -> TimeInterval {
        // Simulate rush hour delays
        let baseETA: TimeInterval = 1800 // 30 minutes
        
        switch hour {
        case 7...9, 17...19: // Rush hours
            return baseETA * 1.5 // 50% longer
        case 22...23, 0...5: // Late night/early morning
            return baseETA * 0.8 // Faster
        default:
            return baseETA
        }
    }
    
    func reset() {
        callCount = 0
        lastOrigin = nil
        lastDestination = nil
        delay = 0
        scenario = .success(eta: 1800, distance: 15000)
    }
}

// MARK: - Mock Types
struct MockRoute {
    let eta: TimeInterval
    let distance: CLLocationDistance
    let polyline: MockPolyline
}

struct MockPolyline {
    let coordinates: [CLLocationCoordinate2D]
}

// MARK: - WizPathError Extension for Testing
extension WizPathError {
    static var noRouteAvailable: WizPathError { .routeUnavailable }
    static var invalidCoordinates: WizPathError { .destinationUnreachable }
    static var networkFailure: WizPathError { .weatherAPIFailed }
}
