import Foundation
import Testing
import CoreLocation
@testable import ForeWiz

@MainActor
@Suite("WizPathService Tests")
struct WizPathServiceTests {
    
    @Test("WizPathService initializes with DI")
    func serviceInitializesWithDI() async throws {
        let mockWeather = MockWeatherRepository()
        let mockLocation = MockLocationRepository()
        
        let service = WizPathService(
            weatherRepository: mockWeather,
            locationRepository: mockLocation
        )
        
        #expect(service != nil)
    }
    
    @Test("Recent destinations save and load")
    func recentDestinationsSaveAndLoad() async throws {
        let mockWeather = MockWeatherRepository()
        let mockLocation = MockLocationRepository()
        let service = WizPathService(
            weatherRepository: mockWeather,
            locationRepository: mockLocation
        )
        
        let testCoordinate = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        let testName = "Test Destination"
        
        service.saveRecentDestination(name: testName, coordinate: testCoordinate)
        let recents = service.loadRecentDestinations()
        
        #expect(recents.contains { $0.name == testName })
        #expect(recents.contains { $0.latitude == testCoordinate.latitude })
        #expect(recents.contains { $0.longitude == testCoordinate.longitude })
    }
    
    @Test("Recent destinations limited to 10")
    func recentDestinationsLimitedToTen() async throws {
        let mockWeather = MockWeatherRepository()
        let mockLocation = MockLocationRepository()
        let service = WizPathService(
            weatherRepository: mockWeather,
            locationRepository: mockLocation
        )
        
        Foundation.UserDefaults.standard.removeObject(forKey: AppKeys.UserDefaults.wizPathRecentDestinations)
        
        for i in 0..<15 {
            service.saveRecentDestination(
                name: "Destination \(i)",
                coordinate: CLLocationCoordinate2D(latitude: Double(i), longitude: Double(i))
            )
        }
        
        let recents = service.loadRecentDestinations()
        #expect(recents.count <= 10)
    }
    
    @Test("Recent destinations are deduplicated")
    func recentDestinationsAreDeduplicated() async throws {
        let mockWeather = MockWeatherRepository()
        let mockLocation = MockLocationRepository()
        let service = WizPathService(
            weatherRepository: mockWeather,
            locationRepository: mockLocation
        )
        
        Foundation.UserDefaults.standard.removeObject(forKey: AppKeys.UserDefaults.wizPathRecentDestinations)
        
        let coord1 = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        let coord2 = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        
        service.saveRecentDestination(name: "Istanbul", coordinate: coord1)
        service.saveRecentDestination(name: "Ankara", coordinate: coord2)
        service.saveRecentDestination(name: "Istanbul", coordinate: coord1)
        
        let recents = service.loadRecentDestinations()
        let istanbulCount = recents.filter { $0.name == "Istanbul" }.count
        #expect(istanbulCount == 1)
        #expect(recents.first?.name == "Istanbul")
    }
    
    @Test("GetCurrentLocation returns mock location")
    func getCurrentLocationReturnsMockLocation() async throws {
        let mockWeather = MockWeatherRepository()
        let mockLocation = MockLocationRepository()
        let service = WizPathService(
            weatherRepository: mockWeather,
            locationRepository: mockLocation
        )
        
        let location = try await service.getCurrentLocation()
        
        #expect(location.latitude == 41.0082)
        #expect(location.longitude == 28.9784)
    }
    
    @Test("WizPathCache stores and retrieves routes")
    func wizPathCacheStoresAndRetrievesRoutes() async throws {
        let cache = WizPathCache.shared
        
        cache.clear()
        
        let origin = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        let destination = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        
        let testRoute = WizPathRoute(
            id: UUID(),
            origin: origin,
            destination: destination,
            travelMode: .car,
            departureTime: Date(),
            segments: [],
            totalDuration: 1800,
            totalDistance: 15000,
            polyline: nil
        )
        
        cache.store(route: testRoute)
        
        let retrieved = cache.route(origin: origin, destination: destination, mode: .car)
        #expect(retrieved != nil)
        #expect(retrieved?.totalDuration == 1800)
    }
    
    @Test("WizPathCache returns nil for missing routes")
    func wizPathCacheReturnsNilForMissingRoutes() async throws {
        let cache = WizPathCache.shared
        cache.clear()
        
        let origin = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        let destination = CLLocationCoordinate2D(latitude: 50.0, longitude: 40.0)
        
        let retrieved = cache.route(origin: origin, destination: destination, mode: .car)
        #expect(retrieved == nil)
    }
    
    @Test("WizPathCache clear removes all routes")
    func wizPathCacheClearRemovesAllRoutes() async throws {
        let cache = WizPathCache.shared
        
        let origin = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        let destination = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        
        let testRoute = WizPathRoute(
            id: UUID(),
            origin: origin,
            destination: destination,
            travelMode: .car,
            departureTime: Date(),
            segments: [],
            totalDuration: 1800,
            totalDistance: 15000,
            polyline: nil
        )
        
        cache.store(route: testRoute)
        cache.clear()
        
        let retrieved = cache.route(origin: origin, destination: destination, mode: .car)
        #expect(retrieved == nil)
    }
    
    @Test("WizPathRoute overall risk calculation")
    func wizPathRouteOverallRiskCalculation() async throws {
        let goodSegment = WizPathSegment(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            estimatedArrival: Date(),
            distanceFromStart: 0,
            travelTime: 0,
            weather: SegmentWeather(
                condition: .clear,
                temperature: 25,
                precipitationChance: 0,
                windSpeed: 5,
                visibility: 10,
                severity: .good
            )
        )
        
        let cautionSegment = WizPathSegment(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            estimatedArrival: Date(),
            distanceFromStart: 5000,
            travelTime: 300,
            weather: SegmentWeather(
                condition: .rain,
                temperature: 20,
                precipitationChance: 0.7,
                windSpeed: 15,
                visibility: 8,
                severity: .caution
            )
        )
        
        let routeWithCaution = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            departureTime: Date(),
            segments: [goodSegment, cautionSegment],
            totalDuration: 600,
            totalDistance: 10000,
            polyline: nil
        )
        
        #expect(routeWithCaution.overallRisk == .caution)
        
        let severeSegment = WizPathSegment(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: 43.0, longitude: 31.0),
            estimatedArrival: Date(),
            distanceFromStart: 10000,
            travelTime: 600,
            weather: SegmentWeather(
                condition: .thunderstorm,
                temperature: 18,
                precipitationChance: 0.9,
                windSpeed: 60,
                visibility: 2,
                severity: .severe
            )
        )
        
        let routeWithSevere = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 43.0, longitude: 31.0),
            travelMode: .car,
            departureTime: Date(),
            segments: [goodSegment, cautionSegment, severeSegment],
            totalDuration: 900,
            totalDistance: 15000,
            polyline: nil
        )
        
        #expect(routeWithSevere.overallRisk == .severe)
        
        let routeWithGood = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            departureTime: Date(),
            segments: [goodSegment],
            totalDuration: 300,
            totalDistance: 5000,
            polyline: nil
        )
        
        #expect(routeWithGood.overallRisk == .good)
    }
    
    @Test("WizPathRoute weather change points detection")
    func wizPathRouteWeatherChangePointsDetection() async throws {
        let clearSegment = WizPathSegment(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            estimatedArrival: Date(),
            distanceFromStart: 0,
            travelTime: 0,
            weather: SegmentWeather(
                condition: .clear,
                temperature: 25,
                precipitationChance: 0,
                windSpeed: 5,
                visibility: 10,
                severity: .good
            )
        )
        
        let rainSegment = WizPathSegment(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            estimatedArrival: Date(),
            distanceFromStart: 5000,
            travelTime: 300,
            weather: SegmentWeather(
                condition: .rain,
                temperature: 20,
                precipitationChance: 0.7,
                windSpeed: 15,
                visibility: 8,
                severity: .caution
            )
        )
        
        let anotherClearSegment = WizPathSegment(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: 43.0, longitude: 31.0),
            estimatedArrival: Date(),
            distanceFromStart: 10000,
            travelTime: 600,
            weather: SegmentWeather(
                condition: .clear,
                temperature: 26,
                precipitationChance: 0,
                windSpeed: 4,
                visibility: 12,
                severity: .good
            )
        )
        
        let route = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 43.0, longitude: 31.0),
            travelMode: .car,
            departureTime: Date(),
            segments: [clearSegment, rainSegment, anotherClearSegment],
            totalDuration: 600,
            totalDistance: 10000,
            polyline: nil
        )
        
        let changePoints = route.weatherChangePoints
        #expect(changePoints.count == 3)
        #expect(changePoints[0].weather?.condition == .clear)
        #expect(changePoints[1].weather?.condition == .rain)
        #expect(changePoints[2].weather?.condition == .clear)
    }
    
    @Test("TravelMode segment intervals")
    func travelModeSegmentIntervals() async throws {
        #expect(TravelMode.car.segmentInterval == 15 * 60)
        #expect(TravelMode.walking.segmentInterval == 30 * 60)
    }
    
    @Test("SegmentWeatherCondition severity mapping")
    func segmentWeatherConditionSeverityMapping() async throws {
        #expect(SegmentWeatherCondition.clear.severity == .good)
        #expect(SegmentWeatherCondition.partlyCloudy.severity == .good)
        #expect(SegmentWeatherCondition.cloudy.severity == .fair)
        #expect(SegmentWeatherCondition.rain.severity == .caution)
        #expect(SegmentWeatherCondition.heavyRain.severity == .severe)
        #expect(SegmentWeatherCondition.thunderstorm.severity == .severe)
        #expect(SegmentWeatherCondition.snow.severity == .severe)
    }
}
