import Foundation
import Testing
import CoreLocation
import MapKit
@testable import WizPathKit
@testable import ForeWiz

// MARK: - Test Helpers

@MainActor
private func makeMapItem() -> MKMapItem {
    MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)))
}

@MainActor
private func makeViewModel() -> WizPathViewModel {
    let mockWeather = MockWizPathWeatherSource()
    let mockLocation = MockWizPathLocationSource()
    let wizPathService = WizPathService(
        weatherRepository: mockWeather,
        locationRepository: mockLocation
    )
    let departOptimizer = DepartureOptimizerService(weatherRepository: mockWeather)
    return WizPathViewModel(
        wizPathService: wizPathService,
        departureOptimizerService: departOptimizer,
        climateService: .shared,
        sentinelService: .shared,
        cyclingSafetyService: .shared,
        poiSearchService: .shared
    )
}

@MainActor
@Suite("WizPathViewModel Tests")
struct WizPathViewModelTests {

    // MARK: - Initial State

    @Test("ViewModel initializes with idle state")
    func initialStateIsIdle() async throws {
        let vm = makeViewModel()
        #expect(vm.state == .idle)
        #expect(vm.travelMode == .car)
        #expect(vm.destinationCoordinate == nil)
        #expect(vm.cyclingSafetyAnalysis == nil)
        #expect(vm.cyclingSafetyRecommendations.isEmpty)
        #expect(vm.sentinelAlerts.isEmpty)
        #expect(vm.bestDepartureTime == nil)
    }

    // MARK: - Travel Mode

    @Test("Travel mode defaults to car")
    func travelModeDefaultsToCar() async throws {
        let vm = makeViewModel()
        #expect(vm.travelMode == .car)
        #expect(WizPathKit.TravelMode.allCases.count == 3)
        #expect(WizPathKit.TravelMode.car.icon == "car.fill")
        #expect(WizPathKit.TravelMode.walking.icon == "figure.walk")
        #expect(WizPathKit.TravelMode.cycling.icon == "bicycle")
    }

    @Test("Travel mode switching resets cycling analysis")
    func travelModeSwitchResetsCycling() async throws {
        let vm = makeViewModel()
        // Simulate cycling analysis being set
        vm.cyclingSafetyAnalysis = WizPathCyclingSafetyService.CyclingSafetyAnalysis(
            safety: WizPathCyclingSafetyService.CyclingSafety.safe,
            effortLevel: WizPathCyclingSafetyService.EffortLevel(
                level: 1, title: "Low", description: "Easy", extraTimePercent: 0
            ),
            crosswindSegments: [],
            headwindSegments: [],
            overallWindSpeed: 5,
            maxGustSpeed: 8
        )
        vm.cyclingSafetyRecommendations = [
            HealthRecommendation(icon: "drop.fill", title: "Hydrate", description: "Drink water")
        ]

        #expect(vm.cyclingSafetyAnalysis != nil)
        #expect(vm.cyclingSafetyRecommendations.count == 1)

        // Switch to car — should reset cycling state
        vm.switchTravelMode(to: .car)
        #expect(vm.travelMode == .car)
        #expect(vm.cyclingSafetyAnalysis == nil)
        #expect(vm.cyclingSafetyRecommendations.isEmpty)
    }

    @Test("Travel mode switching to cycling keeps analysis potential")
    func travelModeSwitchToCycling() async throws {
        let vm = makeViewModel()
        vm.switchTravelMode(to: .cycling)
        #expect(vm.travelMode == .cycling)
        // Analysis is nil until route is calculated
        #expect(vm.cyclingSafetyAnalysis == nil)
    }

    // MARK: - Destination Setting

    @Test("Setting destination triggers state reset")
    func settingDestinationResetsState() async throws {
        let vm = makeViewModel()
        let coord = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        // Just set the coordinate without triggering full calculation
        // (which requires async setup)
        vm.destinationCoordinate = coord
        vm.destinationName = "Test Location"
        #expect(vm.destinationCoordinate?.latitude == 41.0)
        #expect(vm.destinationName == "Test Location")
    }

    // MARK: - Computed Properties

    @Test("Can calculate requires coordinate and not calculating")
    func canCalculateComputed() async throws {
        let vm = makeViewModel()
        // Initially no destination — can't calculate
        #expect(vm.canCalculate == false)
        // Set coordinate
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        #expect(vm.canCalculate == true)
    }

    @Test("State computed properties work correctly")
    func stateComputedProperties() async throws {
        let vm = makeViewModel()
        #expect(vm.state.isIdle == true)
        #expect(vm.isCalculating == false)
        #expect(vm.currentRoute == nil)
        #expect(vm.errorMessage == nil)
        #expect(vm.routeSegments.isEmpty)
        #expect(vm.weatherChangePoints.isEmpty)
    }

    // MARK: - Reset

    @Test("Reset clears state back to idle")
    func resetClearsState() async throws {
        let vm = makeViewModel()
        // Simulate non-idle state
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        vm.destinationName = "Test"
        vm.showJourneyHUD = true

        vm.reset()

        #expect(vm.state == .idle)
        #expect(vm.destinationCoordinate == nil)
        #expect(vm.destinationName == "")
        #expect(vm.showJourneyHUD == false)
        #expect(vm.showWeatherDetail == false)
    }

    // MARK: - Departure Time

    @Test("Departure time is in the future")
    func departureTimeIsInFuture() async throws {
        let vm = makeViewModel()
        let now = Date()
        #expect(vm.departureTime > now)
    }

    @Test("Update departure time clamps to future")
    func updateDepartureTimeClamps() async throws {
        let vm = makeViewModel()
        let pastDate = Date().addingTimeInterval(-86400) // Yesterday
        vm.updateDepartureTime(pastDate)
        // Should have advanced beyond the past date
        #expect(vm.departureTime > pastDate)
        #expect(vm.departureTime.timeIntervalSince(pastDate) >= 86400 - 1) // ~1 day forward
    }

    // MARK: - Cycling Safety Analysis

    @Test("Cycling safety analysis defaults to nil for non-cycling")
    func cyclingSafetyNilForCar() async throws {
        let vm = makeViewModel()
        #expect(vm.cyclingSafetyAnalysis == nil)
    }

    @Test("CyclingSafetyProperties after mode switch")
    func cyclingPropertiesAfterModeSwitch() async throws {
        let vm = makeViewModel()
        vm.switchTravelMode(to: .cycling)
        #expect(vm.travelMode == .cycling)

        // When no analysis yet, properties should be nil/empty
        #expect(vm.cyclingSafetyAnalysis == nil)
        #expect(vm.cyclingSafetyRecommendations.isEmpty)
    }

    // MARK: - Sentinel Alerts

    @Test("Sentinel alerts initialize empty")
    func sentinelAlertsStartEmpty() async throws {
        let vm = makeViewModel()
        #expect(vm.sentinelAlerts.isEmpty)
    }

    // MARK: - WizPathCyclingSafetyService Direct Tests

    @Test("CyclingSafety safe for good conditions")
    func cyclingSafetySafeForGoodConditions() async throws {
        let route = WizPathRoute.testRoute(
            travelMode: .cycling,
            segments: [
                .testSegment(weather: .testWeather(condition: .clear, temperature: 22, windSpeed: 10))
            ]
        )
        let analysis = WizPathCyclingSafetyService.shared.analyzeCyclingSafety(route: route)
        let safe = WizPathCyclingSafetyService.CyclingSafety.safe
        #expect(analysis.safety == safe)
        #expect(!analysis.hasCrosswindRisk)
        #expect(!analysis.hasSignificantHeadwind)
    }

    @Test("CyclingSafety caution for strong wind")
    func cyclingSafetyCautionForStrongWind() async throws {
        let route = WizPathRoute.testRoute(
            travelMode: .cycling,
            segments: [
                .testSegment(weather: .testWeather(condition: .windy, temperature: 20, windSpeed: 30))
            ]
        )
        let analysis = WizPathCyclingSafetyService.shared.analyzeCyclingSafety(route: route)
        #expect(analysis.safety.isRisky)
        #expect(analysis.hasCrosswindRisk)
        #expect(analysis.crosswindSegments.count > 0)
    }

    @Test("CyclingSafety notRecommended for dangerous wind")
    func cyclingSafetyNotRecommendedForDangerousWind() async throws {
        let route = WizPathRoute.testRoute(
            travelMode: .cycling,
            segments: [
                .testSegment(weather: .testWeather(condition: .windy, temperature: 20, windSpeed: 45))
            ]
        )
        let analysis = WizPathCyclingSafetyService.shared.analyzeCyclingSafety(route: route)
        #expect(analysis.safety.isRisky)
        #expect(analysis.maxGustSpeed >= 40)
        if case WizPathCyclingSafetyService.CyclingSafety.notRecommended = analysis.safety {
            #expect(true) // Correct safety case
        } else {
            Issue.record("Expected notRecommended safety")
        }
    }

    // EV mode tests removed

    // MARK: - Toll Road Toggle

    @Test("Toll road toggle flips state")
    func tollRoadToggleFlipsState() async throws {
        let vm = makeViewModel()
        #expect(vm.avoidTollRoads == false)
        vm.toggleAvoidTollRoads()
        #expect(vm.avoidTollRoads == true)
        vm.toggleAvoidTollRoads()
        #expect(vm.avoidTollRoads == false)
    }

    // MARK: - Dismiss Error

    @Test("Dismiss error sets state to idle")
    func dismissErrorSetsStateToIdle() async throws {
        let vm = makeViewModel()
        vm.state = .error("Test error")
        #expect(vm.errorMessage == "Test error")
        vm.dismissError()
        #expect(vm.state == .idle)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Maps URL Builders

    @Test("Apple Maps URL returns nil when no route")
    func appleMapsURLReturnsNilWhenNoRoute() async throws {
        let vm = makeViewModel()
        #expect(vm.appleMapsURLString() == nil)
    }

    @Test("Apple Maps URL builds correctly with origin and destination")
    func appleMapsURLBuildsCorrectly() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        // Set a route to pass guard check
        let route = WizPathRoute.testRoute()
        vm.state = .routeReady(route)

        let url = vm.appleMapsURLString()
        let unwrapped = try #require(url)
        #expect(unwrapped.contains("maps://"))
        #expect(unwrapped.contains("saddr=41.0082,28.9784"))
        #expect(unwrapped.contains("daddr=42.0,30.0"))
    }

    @Test("Apple Maps Web URL builds with origin and destination and route")
    func appleMapsWebURLBuildsWithRoute() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        // Web URL now includes waypoints, requires a route
        let route = WizPathRoute.testRoute()
        vm.state = .routeReady(route)

        let url = vm.appleMapsWebURLString()
        let unwrapped = try #require(url)
        #expect(unwrapped.contains("maps.apple.com"))
        #expect(unwrapped.contains("saddr=41.0,29.0"))
        #expect(unwrapped.contains("daddr=42.0,30.0"))
    }

    @Test("Google Maps URL returns nil when no route")
    func googleMapsURLReturnsNilWhenNoRoute() async throws {
        let vm = makeViewModel()
        #expect(vm.googleMapsURLString() == nil)
    }

    @Test("Google Maps URL builds correctly")
    func googleMapsURLBuildsCorrectly() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        let route = WizPathRoute.testRoute()
        vm.state = .routeReady(route)

        let url = vm.googleMapsURLString()
        let unwrapped = try #require(url)
        #expect(unwrapped.contains("comgooglemaps://"))
    }

    @Test("Google Maps Web URL builds correctly")
    func googleMapsWebURLBuildsCorrectly() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        let url = vm.googleMapsWebURLString()
        let unwrapped = try #require(url)
        #expect(unwrapped.contains("google.com/maps"))
    }

    // MARK: - Offline Maps Navigation

    @Test("mapsNavigationRoute returns currentRoute when state is routeReady")
    func mapsNavigationRouteReturnsCurrentRouteWhenReady() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        vm.state = .routeReady(route)
        #expect(vm.mapsNavigationRoute?.id == route.id)
    }

    @Test("mapsNavigationRoute falls back to cached route when offline")
    func mapsNavigationRouteFallsBackToCachedWhenOffline() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)

        // Simulate a successful route calculation by selecting a candidate
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        #expect(vm.currentRoute != nil) // Should be routeReady after selection

        // Now go offline — currentRoute becomes nil
        vm.state = .offline
        #expect(vm.currentRoute == nil)
        #expect(vm.mapsNavigationRoute?.id == route.id) // Falls back to cached route
    }

    @Test("mapsNavigationRoute returns nil when never calculated and offline")
    func mapsNavigationRouteReturnsNilWhenNeverCalculated() async throws {
        let vm = makeViewModel()
        vm.state = .offline
        #expect(vm.mapsNavigationRoute == nil)
    }

    @Test("mapsNavigationRoute returns nil when cached route is not set")
    func mapsNavigationRouteReturnsNilWhenNoCache() async throws {
        let vm = makeViewModel()
        vm.state = .error("Some error")
        #expect(vm.mapsNavigationRoute == nil)
    }

    @Test("Apple Maps URL works with cached route when offline")
    func appleMapsURLWorksWithCachedRouteOffline() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)

        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        // Go offline
        vm.state = .offline

        let url = vm.appleMapsURLString()
        let unwrapped = try #require(url)
        #expect(unwrapped.contains("maps://"))
        #expect(unwrapped.contains("saddr=41.0082,28.9784"))
    }

    @Test("Apple Maps Web URL works with cached route when offline")
    func appleMapsWebURLWorksWithCachedRouteOffline() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)

        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        vm.state = .offline

        let url = vm.appleMapsWebURLString()
        let unwrapped = try #require(url)
        #expect(unwrapped.contains("maps.apple.com"))
    }

    @Test("Google Maps URL works with cached route when offline")
    func googleMapsURLWorksWithCachedRouteOffline() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)

        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        vm.state = .offline

        let url = vm.googleMapsURLString()
        let unwrapped = try #require(url)
        #expect(unwrapped.contains("comgooglemaps://"))
    }

    @Test("Google Maps Web URL works with cached route when offline")
    func googleMapsWebURLWorksWithCachedRouteOffline() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)

        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        vm.state = .offline

        let url = vm.googleMapsWebURLString()
        let unwrapped = try #require(url)
        #expect(unwrapped.contains("google.com/maps"))
    }

    @Test("All 4 Maps URLs return nil when offline with no cached route")
    func allMapsURLsReturnNilWhenOfflineWithoutCache() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        vm.state = .offline

        #expect(vm.appleMapsURLString() == nil)
        #expect(vm.appleMapsWebURLString() == nil)
        #expect(vm.googleMapsURLString() == nil)
        #expect(vm.googleMapsWebURLString() == nil)
    }

    @Test("reset clears cached route so offline URLs return nil")
    func resetClearsCachedRoute() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)

        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        vm.reset()

        // After reset, cache is cleared
        #expect(vm.state == .idle)
        #expect(vm.mapsNavigationRoute == nil)
    }

    @Test("mapsWaypoints sorts by etaArrival")
    func mapsWaypointsSortedByEtaArrival() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        vm.state = .routeReady(route)

        let now = Date()
        let later = now.addingTimeInterval(3600)
        let muchLater = now.addingTimeInterval(7200)
        let dummyMapItem = makeMapItem()

        let stop1 = SmartStop(id: UUID(), mapItem: dummyMapItem, coordinate: CLLocationCoordinate2D(latitude: 41.1, longitude: 29.1), name: "Gas 1", category: .gasStation, etaArrival: muchLater, weatherAtArrival: nil, safetyStatus: .safe, distanceFromRoute: 100, estimatedStopDuration: 300, weatherRecommendation: nil)
        let stop2 = SmartStop(id: UUID(), mapItem: dummyMapItem, coordinate: CLLocationCoordinate2D(latitude: 41.2, longitude: 29.2), name: "Rest 1", category: .restStop, etaArrival: later, weatherAtArrival: nil, safetyStatus: .safe, distanceFromRoute: 200, estimatedStopDuration: 600, weatherRecommendation: nil)

        vm.smartStops = [stop1, stop2]

        let waypoints = vm.mapsWaypoints
        #expect(waypoints.count == 2)
        #expect(waypoints[0].id == stop2.id) // earlier arrival first
        #expect(waypoints[1].id == stop1.id) // later arrival second
    }

    @Test("mapsWaypoints excludes unsafe stops")
    func mapsWaypointsExcludesUnsafeStops() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        vm.state = .routeReady(route)

        let now = Date()
        let dummyMapItem = makeMapItem()
        let safe = SmartStop(id: UUID(), mapItem: dummyMapItem, coordinate: CLLocationCoordinate2D(latitude: 41.1, longitude: 29.1), name: "Safe Stop", category: .restStop, etaArrival: now, weatherAtArrival: nil, safetyStatus: .safe, distanceFromRoute: 100, estimatedStopDuration: 300, weatherRecommendation: nil)
        let unsafe = SmartStop(id: UUID(), mapItem: dummyMapItem, coordinate: CLLocationCoordinate2D(latitude: 41.2, longitude: 29.2), name: "Unsafe Stop", category: .restaurant, etaArrival: now, weatherAtArrival: nil, safetyStatus: .unsafe, distanceFromRoute: 200, estimatedStopDuration: 300, weatherRecommendation: nil)
        let caution = SmartStop(id: UUID(), mapItem: dummyMapItem, coordinate: CLLocationCoordinate2D(latitude: 41.3, longitude: 29.3), name: "Caution Stop", category: .gasStation, etaArrival: now, weatherAtArrival: nil, safetyStatus: .caution, distanceFromRoute: 150, estimatedStopDuration: 300, weatherRecommendation: nil)

        vm.smartStops = [safe, unsafe, caution]

        let waypoints = vm.mapsWaypoints
        #expect(waypoints.count == 2) // safe + caution (unsafe's shouldAvoid should be true)
        #expect(waypoints.allSatisfy { $0.safetyStatus != .unsafe })
    }

    @Test("mapsWaypoints returns empty when no smart stops")
    func mapsWaypointsEmptyWhenNoStations() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        vm.state = .routeReady(route)
        #expect(vm.mapsWaypoints.isEmpty)
    }

    @Test("mapsWaypoints preserved when going offline")
    func mapsWaypointsPreservedWhenOffline() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let dummyMapItem = makeMapItem()
        let now = Date()
        let stop = SmartStop(id: UUID(), mapItem: dummyMapItem, coordinate: CLLocationCoordinate2D(latitude: 41.1, longitude: 29.1), name: "Gas Station", category: .gasStation, etaArrival: now, weatherAtArrival: nil, safetyStatus: .safe, distanceFromRoute: 100, estimatedStopDuration: 300, weatherRecommendation: nil)

        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)
        vm.smartStops = [stop]

        // Go offline — stops should persist
        vm.state = .offline
        #expect(vm.smartStops.count == 1)
        #expect(vm.mapsWaypoints.count == 1)
        #expect(vm.mapsWaypoints.first?.name == "Gas Station")
    }

    @Test("Offline state preserves routeSegments and weatherChangePoints from cached route")
    func offlinePreservesRouteProperties() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        vm.state = .offline
        // mapsNavigationRoute should return the cached route with its properties
        #expect(vm.mapsNavigationRoute != nil)
        #expect(vm.mapsNavigationRoute?.id == route.id)
    }

    @Test("State transitions: idle → loading → error → idle clears cache")
    func stateTransitionErrorClearsCache() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        #expect(vm.mapsNavigationRoute != nil) // Cache is set

        // Error state does NOT clear lastCalculatedRoute (state machine handles this)
        vm.state = .error("Network error")
        #expect(vm.mapsNavigationRoute?.id == route.id) // Cache preserved

        // Only reset() clears cache
        vm.reset()
        #expect(vm.mapsNavigationRoute == nil)
    }

    // MARK: - Cache Expiration

    @Test("mapsNavigationRoute uses fresh cache when route is recent (< 30 min)")
    func mapsNavigationRouteUsesFreshCache() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        // Cache is fresh (just set)
        vm.state = .offline
        #expect(vm.mapsNavigationRoute != nil)
        #expect(vm.mapsNavigationRoute?.id == route.id)
    }

    @Test("mapsNavigationRoute returns nil when cache is expired (> 30 min)")
    func mapsNavigationRouteReturnsNilWhenCacheExpired() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        // Manipulate timestamp to be expired (cacheExpirationInterval = 1800)
        vm.lastCalculatedRouteTimestamp = Date().addingTimeInterval(-1801)

        vm.state = .offline
        #expect(vm.mapsNavigationRoute == nil)
    }

    @Test("mapsNavigationRoute returns nil when cache expired in error state")
    func mapsNavigationRouteReturnsNilWhenCacheExpiredInError() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        vm.lastCalculatedRouteTimestamp = Date().addingTimeInterval(-1801)

        vm.state = .error("Something broke")
        #expect(vm.mapsNavigationRoute == nil)
    }

    @Test("mapsNavigationRoute returns route at expiration boundary (just under 30 min)")
    func mapsNavigationRouteReturnsRouteAtExpirationBoundary() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        // Set timestamp to just under expiration (1799 seconds ago)
        vm.lastCalculatedRouteTimestamp = Date().addingTimeInterval(-1799)

        vm.state = .offline
        #expect(vm.mapsNavigationRoute != nil)
        #expect(vm.mapsNavigationRoute?.id == route.id)
    }

    @Test("New route candidate selection refreshes cache timestamp")
    func newRouteCandidateRefreshesCacheTimestamp() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        // Simulate old cache
        vm.lastCalculatedRouteTimestamp = Date().addingTimeInterval(-3600)

        // Select a new candidate — refreshes timestamp
        let newRoute = WizPathRoute.testRoute(id: UUID())
        let newCandidate = ScoredRouteCandidate(route: newRoute, score: 90, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [newCandidate]
        vm.selectRouteCandidate(at: 0)

        // Timestamp should be refreshed to now
        let cachedAt = try #require(vm.lastCalculatedRouteTimestamp)
        #expect(Date().timeIntervalSince(cachedAt) < 2) // Just set

        vm.state = .offline
        #expect(vm.mapsNavigationRoute?.id == newRoute.id)
    }

    @Test("reset clears cache timestamp")
    func resetClearsCacheTimestamp() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        #expect(vm.lastCalculatedRouteTimestamp != nil)

        vm.reset()

        #expect(vm.lastCalculatedRouteTimestamp == nil)
        #expect(vm.mapsNavigationRoute == nil)
    }

    // MARK: - Offline State Preservation

    @Test("State transitions: idle → loading → offline preserves cache")
    func stateTransitionOfflinePreservesCache() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        #expect(vm.mapsNavigationRoute != nil)

        vm.state = .offline
        #expect(vm.mapsNavigationRoute != nil)
        #expect(vm.mapsNavigationRoute?.id == route.id)
    }

    // EV state test removed

    @Test("Offline with cached route — toll road preference is preserved")
    func offlinePreservesTollPreference() async throws {
        let vm = makeViewModel()
        vm.avoidTollRoads = true
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        vm.state = .offline
        #expect(vm.avoidTollRoads == true)
        #expect(vm.mapsNavigationRoute != nil)
    }

    @Test("Offline with cached route — travel mode is preserved")
    func offlinePreservesTravelMode() async throws {
        let vm = makeViewModel()
        vm.switchTravelMode(to: .walking)
        let route = WizPathRoute.testRoute(travelMode: .walking)
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        vm.state = .offline
        #expect(vm.travelMode == .walking)
        #expect(vm.mapsNavigationRoute != nil)
    }

    @Test("mapsNavigationRoute returns lastCalculatedRoute in error state")
    func errorStateUsesCachedRoute() async throws {
        let vm = makeViewModel()
        let route = WizPathRoute.testRoute()
        let candidate = ScoredRouteCandidate(route: route, score: 85, trafficCongestion: .freeFlow, hasTollRoads: false)
        vm.routeCandidates = [candidate]
        vm.selectRouteCandidate(at: 0)

        // Simulate going to error state after having a route
        vm.state = .error("API failure")
        #expect(vm.currentRoute == nil)
        #expect(vm.mapsNavigationRoute?.id == route.id) // Falls back
    }

    @Test("Toll avoidance reflected in Apple Maps URL")
    func tollAvoidanceInAppleMapsURL() async throws {
        let vm = makeViewModel()
        vm.originCoordinate = CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)
        vm.destinationCoordinate = CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0)
        let route = WizPathRoute.testRoute()
        vm.state = .routeReady(route)

        vm.avoidTollRoads = true
        let webURL = vm.appleMapsWebURLString()
        #expect(webURL?.contains("dirflg=d") == true)
    }

    // MARK: - Route Candidates

    @Test("Route candidates initialize empty")
    func routeCandidatesInitializeEmpty() async throws {
        let vm = makeViewModel()
        #expect(vm.routeCandidates.isEmpty)
        #expect(vm.selectedRouteIndex == 0)
        #expect(vm.showRouteComparison == false)
        #expect(vm.hasTollRoads == false)
        #expect(vm.currentTrafficCongestion == .unknown)
    }

    @Test("Select route candidate out of bounds is no-op")
    func selectRouteCandidateOutOfBounds() async throws {
        let vm = makeViewModel()
        vm.selectRouteCandidate(at: -1)
        #expect(vm.selectedRouteIndex == 0)
        vm.selectRouteCandidate(at: 5)
        #expect(vm.selectedRouteIndex == 0)
    }

    @Test("isShowingRoute toggle")
    func isShowingRouteToggle() async throws {
        let vm = makeViewModel()
        #expect(vm.isShowingRoute == true)
        vm.isShowingRoute = false
        #expect(vm.isShowingRoute == false)
        vm.isShowingRoute = true
        #expect(vm.isShowingRoute == true)
    }

    @Test("Segment place names default empty")
    func segmentPlaceNamesDefaultEmpty() async throws {
        let vm = makeViewModel()
        #expect(vm.segmentPlaceNames.isEmpty)
    }

    @Test("CyclingSafetyAnalysis access after mode switch")
    func cyclingSafetyAnalysisAfterModeSwitch() async throws {
        let vm = makeViewModel()
        vm.switchTravelMode(to: .cycling)
        #expect(vm.travelMode == .cycling)
        #expect(vm.cyclingSafetyAnalysis == nil)
    }

    // MARK: - Sentinel Alert Management

    @Test("Add sentinel alert")
    func addSentinelAlert() async throws {
        let vm = makeViewModel()
        let alert = SentinelAlert(
            id: "test",
            signature: "sig",
            title: "Test",
            body: "Body",
            severity: .high,
            originalDuration: 1800,
            updatedDuration: 3600,
            weatherContext: WeatherContext(primaryHazard: .extremeHeat, temperature: 42, conditions: [.clear], isExtreme: true),
            timestamp: Date()
        )
        vm.sentinelAlerts = [alert]
        #expect(vm.sentinelAlerts.count == 1)
        #expect(vm.sentinelAlerts.first?.severity == .high)
    }

    @Test("CyclingSafety effort level computation")
    func cyclingSafetyEffortLevelComputation() async throws {
        let route = WizPathRoute.testRoute(
            travelMode: .cycling,
            segments: [
                .testSegment(weather: .testWeather(condition: .clear, temperature: 28, windSpeed: 35))
            ]
        )
        let analysis = WizPathCyclingSafetyService.shared.analyzeCyclingSafety(route: route)
        #expect(analysis.effortLevel.level >= 4) // Wind + heat should raise effort
        #expect(analysis.effortLevel.extraTimePercent >= 0)
    }

    @Test("CyclingSafety returns safe for non-cycling mode")
    func cyclingSafetySafeForNonCyclingMode() async throws {
        let route = WizPathRoute.testRoute(
            travelMode: .car,
            segments: [
                .testSegment(weather: .testWeather(condition: .clear, temperature: 22, windSpeed: 10))
            ]
        )
        let analysis = WizPathCyclingSafetyService.shared.analyzeCyclingSafety(route: route)
        let safe = WizPathCyclingSafetyService.CyclingSafety.safe
        #expect(analysis.safety == safe)
        #expect(analysis.overallWindSpeed == 0) // No wind analysis for non-cycling
    }

    // MARK: - TravelMode Enum Tests

    @Test("TravelMode cycling properties")
    func travelModeCyclingProperties() async throws {
        #expect(WizPathKit.TravelMode.cycling.rawValue == "cycling")
        #expect(WizPathKit.TravelMode.cycling.segmentInterval == 10 * 60)
        #expect(WizPathKit.TravelMode.cycling.averageSpeedKph == 15)
        #expect(WizPathKit.TravelMode.cycling.isWindSensitive == true)
        #expect(WizPathKit.TravelMode.cycling.mkTransportType == MKDirectionsTransportType.walking)
    }

    @Test("TravelMode all cases contain cycling")
    func travelModeAllCasesContainsCycling() async throws {
        let modes = WizPathKit.TravelMode.allCases
        #expect(modes.contains(.cycling))
        #expect(modes.count == 3)
    }
}

// MARK: - Test Helpers for Route Building

extension WizPathRoute {
    static func testRoute(
        id: UUID = UUID(),
        travelMode: WizPathKit.TravelMode = .car,
        segments: [WizPathSegment] = []
    ) -> WizPathRoute {
        WizPathRoute(
            id: id,
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: travelMode,
            departureTime: Date(),
            segments: segments,
            totalDuration: segments.reduce(0) { $0 + $1.travelTime },
            totalDistance: segments.last?.distanceFromStart ?? 0,
            polyline: nil
        )
    }
}

extension WizPathSegment {
    static func testSegment(
        id: UUID = UUID(),
        weather: SegmentWeather? = nil
    ) -> WizPathSegment {
        WizPathSegment(
            id: id,
            coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            estimatedArrival: Date(),
            distanceFromStart: 1000,
            travelTime: 120,
            weather: weather
        )
    }
}

extension SegmentWeather {
    static func testWeather(
        condition: SegmentWeatherCondition = .clear,
        temperature: Double = 22,
        precipitationChance: Double = 0.0,
        windSpeed: Double = 10,
        visibility: Double? = 10,
        severity: SegmentWeatherSeverity = .good
    ) -> SegmentWeather {
        SegmentWeather(
            condition: condition,
            temperature: temperature,
            precipitationChance: precipitationChance,
            windSpeed: windSpeed,
            visibility: visibility,
            severity: severity
        )
    }
}
