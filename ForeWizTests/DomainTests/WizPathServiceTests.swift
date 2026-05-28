import Foundation
import Testing
import CoreLocation
@testable import WizPathKit
@testable import ForeWiz

@MainActor
@Suite("WizPathService Tests")
struct WizPathServiceTests {
    
    @Test("WizPathService initializes with DI")
    func serviceInitializesWithDI() async throws {
        let mockWeather = MockWizPathWeatherSource()
        let mockLocation = MockWizPathLocationSource()
        
        let service = WizPathService(
            weatherRepository: mockWeather,
            locationRepository: mockLocation
        )
        
        #expect(service != nil)
    }
    
    @Test("Recent destinations save and load")
    func recentDestinationsSaveAndLoad() async throws {
        let mockWeather = MockWizPathWeatherSource()
        let mockLocation = MockWizPathLocationSource()
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
        let mockWeather = MockWizPathWeatherSource()
        let mockLocation = MockWizPathLocationSource()
        let service = WizPathService(
            weatherRepository: mockWeather,
            locationRepository: mockLocation
        )
        
        Foundation.UserDefaults.standard.removeObject(forKey: WizPathKitKeys.UserDefaults.wizPathRecentDestinations)
        
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
        let mockWeather = MockWizPathWeatherSource()
        let mockLocation = MockWizPathLocationSource()
        let service = WizPathService(
            weatherRepository: mockWeather,
            locationRepository: mockLocation
        )
        
        Foundation.UserDefaults.standard.removeObject(forKey: WizPathKitKeys.UserDefaults.wizPathRecentDestinations)
        
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
        let mockWeather = MockWizPathWeatherSource()
        let mockLocation = MockWizPathLocationSource()
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
        let cache = WizPathCache()
        
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
        
        await cache.store(route: testRoute)
        
        let retrieved = await cache.route(origin: origin, destination: destination, mode: .car)
        #expect(retrieved != nil)
        #expect(retrieved?.totalDuration == 1800)
    }
    
    @Test("WizPathCache returns nil for missing routes")
    func wizPathCacheReturnsNilForMissingRoutes() async throws {
        let cache = WizPathCache()
        
        let origin = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        let destination = CLLocationCoordinate2D(latitude: 50.0, longitude: 40.0)
        
        let retrieved = await cache.route(origin: origin, destination: destination, mode: .car)
        #expect(retrieved == nil)
    }
    
    @Test("WizPathCache clear removes all routes")
    func wizPathCacheClearRemovesAllRoutes() async throws {
        let cache = WizPathCache()
        
        let origin = CLLocationCoordinate2D(latitude: 55.123, longitude: 37.456)
        let destination = CLLocationCoordinate2D(latitude: 56.789, longitude: 38.012)
        
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
        
        await cache.store(route: testRoute)
        
        // Verify it was stored
        let storedRoute = await cache.route(origin: origin, destination: destination, mode: .car)
        #expect(storedRoute != nil)
        
        await cache.clear()
        
        let retrieved = await cache.route(origin: origin, destination: destination, mode: .car)
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

    // MARK: - Route Risk Enum Tests

    @Test("RouteRisk enum values and colors")
    func routeRiskEnumValuesAndColors() async throws {
        #expect(RouteRisk.good.rawValue == "good")
        #expect(RouteRisk.caution.rawValue == "caution")
        #expect(RouteRisk.severe.rawValue == "severe")

        #expect(RouteRisk.good.color == "#34C759")
        #expect(RouteRisk.caution.color == "#FF9500")
        #expect(RouteRisk.severe.color == "#FF3B30")
    }

    @Test("RouteRisk localized titles are non-empty")
    func routeRiskLocalizedTitles() async throws {
        #expect(!RouteRisk.good.localizedTitle.isEmpty)
        #expect(!RouteRisk.caution.localizedTitle.isEmpty)
        #expect(!RouteRisk.severe.localizedTitle.isEmpty)
    }

    @Test("RouteRisk safety score mapping")
    func routeRiskSafetyScoreMapping() async throws {
        #expect(RouteRisk.good.safetyScore == 85)
        #expect(RouteRisk.caution.safetyScore == 60)
        #expect(RouteRisk.severe.safetyScore == 30)
    }

    // MARK: - ScoredRouteCandidate Tests

    @Test("ScoredRouteCandidate computed properties")
    func scoredRouteCandidateComputedProperties() async throws {
        let route = WizPathRoute.testRoute(segments: [])

        let bestCandidate = ScoredRouteCandidate(route: route, score: 85)
        #expect(bestCandidate.isBest == true)
        #expect(bestCandidate.isGood == false)
        #expect(bestCandidate.scoreLabel == "Best" || !bestCandidate.scoreLabel.isEmpty)
        #expect(bestCandidate.scoreColorHex == "#34C759")

        let goodCandidate = ScoredRouteCandidate(route: route, score: 70)
        #expect(goodCandidate.isBest == false)
        #expect(goodCandidate.isGood == true)
        #expect(goodCandidate.isModerate == false)

        let moderateCandidate = ScoredRouteCandidate(route: route, score: 50)
        #expect(moderateCandidate.isModerate == true)
        #expect(moderateCandidate.isPoor == false)
        #expect(goodCandidate.scoreColorHex == "#30D158")

        let poorCandidate = ScoredRouteCandidate(route: route, score: 20)
        #expect(poorCandidate.isPoor == true)
        #expect(poorCandidate.scoreColorHex == "#FF3B30")
    }

    @Test("ScoredRouteCandidate formatted distance")
    func scoredRouteCandidateFormattedDistance() async throws {
        let shortRoute = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 41.5, longitude: 29.5),
            travelMode: .car,
            departureTime: Date(),
            segments: [],
            totalDuration: 600,
            totalDistance: 5000,
            polyline: nil
        )
        let candidate = ScoredRouteCandidate(route: shortRoute, score: 90)
        #expect(!candidate.formattedDistance.isEmpty)
    }

    // MARK: - Segment Tests

    @Test("WizPathSegment eta display format")
    func wizPathSegmentEtaDisplay() async throws {
        let segment = WizPathSegment(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            estimatedArrival: Date(),
            distanceFromStart: 1000,
            travelTime: 120,
            weather: nil
        )
        #expect(!segment.etaDisplay.isEmpty)
    }

    @Test("WizPathSegment weather condition icons")
    func weatherConditionIcons() async throws {
        #expect(SegmentWeatherCondition.clear.iconName == "sun.max.fill")
        #expect(SegmentWeatherCondition.thunderstorm.iconName == "cloud.bolt.rain.fill")
        #expect(SegmentWeatherCondition.fog.iconName == "cloud.fog.fill")
        #expect(SegmentWeatherCondition.windy.iconName == "wind")
    }

    @Test("SegmentWeatherSeverity severity order")
    func segmentWeatherSeverityOrder() async throws {
        #expect(SegmentWeatherSeverity.good.severityOrder == 0)
        #expect(SegmentWeatherSeverity.fair.severityOrder == 1)
        #expect(SegmentWeatherSeverity.caution.severityOrder == 2)
        #expect(SegmentWeatherSeverity.severe.severityOrder == 3)
    }

    // MARK: - TravelMode Tests

    @Test("TravelMode all properties")
    func travelModeAllProperties() async throws {
        #expect(TravelMode.allCases.count == 3)
        #expect(TravelMode.walking.icon == "figure.walk")
        #expect(TravelMode.walking.averageSpeedKph == 5)
        #expect(TravelMode.cycling.averageSpeedKph == 15)
        #expect(TravelMode.car.averageSpeedKph == 40)
    }

    @Test("TravelMode wind sensitivity")
    func travelModeWindSensitivity() async throws {
        #expect(TravelMode.car.isWindSensitive == false)
        #expect(TravelMode.walking.isWindSensitive == false)
        #expect(TravelMode.cycling.isWindSensitive == true)
    }

    // MARK: - WizPathError Tests

    @Test("WizPathError localized descriptions")
    func wizPathErrorLocalizedDescriptions() async throws {
        #expect(WizPathError.routeUnavailable.errorDescription?.isEmpty == false)
        #expect(WizPathError.noWalkingPath.errorDescription?.isEmpty == false)
        #expect(WizPathError.weatherAPIFailed.errorDescription?.isEmpty == false)
        #expect(WizPathError.destinationUnreachable.errorDescription?.isEmpty == false)
        #expect(WizPathError.invalidDepartureTime.errorDescription?.isEmpty == false)
    }

    // MARK: - Traffic Congestion Tests

    @Test("TrafficCongestionLevel order")
    func trafficCongestionLevelOrder() async throws {
        #expect(TrafficCongestionLevel.unknown < TrafficCongestionLevel.freeFlow)
        #expect(TrafficCongestionLevel.freeFlow < TrafficCongestionLevel.moderate)
        #expect(TrafficCongestionLevel.moderate < TrafficCongestionLevel.heavy)
        #expect(TrafficCongestionLevel.heavy < TrafficCongestionLevel.gridlock)
    }

    @Test("TrafficCongestionLevel colors")
    func trafficCongestionLevelColors() async throws {
        #expect(TrafficCongestionLevel.freeFlow.colorHex == "#34C759")
        #expect(TrafficCongestionLevel.moderate.colorHex == "#FFCC00")
        #expect(TrafficCongestionLevel.heavy.colorHex == "#FF9500")
        #expect(TrafficCongestionLevel.gridlock.colorHex == "#FF3B30")
    }

    @Test("TrafficCongestionLevel localized titles")
    func trafficCongestionLevelLocalizedTitles() async throws {
        #expect(!TrafficCongestionLevel.unknown.localizedTitle.isEmpty)
        #expect(!TrafficCongestionLevel.freeFlow.localizedTitle.isEmpty)
        #expect(!TrafficCongestionLevel.moderate.localizedTitle.isEmpty)
        #expect(!TrafficCongestionLevel.heavy.localizedTitle.isEmpty)
        #expect(!TrafficCongestionLevel.gridlock.localizedTitle.isEmpty)
    }

    // MARK: - WizPathRoute JourneyHUD Tests

    @Test("WizPathRoute journeyHUDData generation")
    func wizPathRouteJourneyHUDData() async throws {
        let segments = [
            WizPathSegment(
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
                    visibility: 15,
                    severity: .good
                )
            )
        ]
        let route = WizPathRoute.testRoute(segments: segments)
        let hud = route.journeyHUDData
        #expect(hud.totalDuration == route.totalDuration)
        #expect(hud.safetyScore == 85)
        #expect(hud.durationDisplay.isEmpty == false)
    }

    @Test("WizPathRoute journeyHUDData with hazards")
    func wizPathRouteJourneyHUDDataWithHazards() async throws {
        let segments = [
            WizPathSegment(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                estimatedArrival: Date(),
                distanceFromStart: 0,
                travelTime: 0,
                weather: SegmentWeather(
                    condition: .thunderstorm,
                    temperature: 18,
                    precipitationChance: 0.9,
                    windSpeed: 60,
                    visibility: 2,
                    severity: .severe
                )
            )
        ]
        let route = WizPathRoute.testRoute(segments: segments)
        let hud = route.journeyHUDData
        #expect(hud.hazardCount > 0)
        #expect(hud.activeHazards.count > 0)
        #expect(hud.safetyScore == 30) // severe risk
    }
}
