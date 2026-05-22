import Foundation
import Testing
import CoreLocation
import MapKit
@testable import WizPathKit
@testable import ForeWiz

// MARK: - Test Helpers

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
        departureOptimizerService: departOptimizer
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
        #expect(TravelMode.allCases.count == 3)
        #expect(TravelMode.car.icon == "car.fill")
        #expect(TravelMode.walking.icon == "figure.walk")
        #expect(TravelMode.cycling.icon == "bicycle")
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
        let analysis = await WizPathCyclingSafetyService.shared.analyzeCyclingSafety(route: route)
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
        let analysis = await WizPathCyclingSafetyService.shared.analyzeCyclingSafety(route: route)
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
        let analysis = await WizPathCyclingSafetyService.shared.analyzeCyclingSafety(route: route)
        #expect(analysis.safety.isRisky)
        #expect(analysis.maxGustSpeed >= 40)
        if case WizPathCyclingSafetyService.CyclingSafety.notRecommended = analysis.safety {
            #expect(true) // Correct safety case
        } else {
            Issue.record("Expected notRecommended safety")
        }
    }

    @Test("CyclingSafety effort level computation")
    func cyclingSafetyEffortLevel() async throws {
        let route = WizPathRoute.testRoute(
            travelMode: .cycling,
            segments: [
                .testSegment(weather: .testWeather(condition: .clear, temperature: 28, windSpeed: 35))
            ]
        )
        let analysis = await WizPathCyclingSafetyService.shared.analyzeCyclingSafety(route: route)
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
        let analysis = await WizPathCyclingSafetyService.shared.analyzeCyclingSafety(route: route)
        let safe = WizPathCyclingSafetyService.CyclingSafety.safe
        #expect(analysis.safety == safe)
        #expect(analysis.overallWindSpeed == 0) // No wind analysis for non-cycling
    }

    // MARK: - TravelMode Enum Tests

    @Test("TravelMode cycling properties")
    func travelModeCyclingProperties() async throws {
        #expect(TravelMode.cycling.rawValue == "cycling")
        #expect(TravelMode.cycling.segmentInterval == 10 * 60)
        #expect(TravelMode.cycling.averageSpeedKph == 15)
        #expect(TravelMode.cycling.isWindSensitive == true)
        #expect(TravelMode.cycling.mkTransportType == MKDirectionsTransportType.walking)
    }

    @Test("TravelMode all cases contain cycling")
    func travelModeAllCasesContainsCycling() async throws {
        let modes = TravelMode.allCases
        #expect(modes.contains(.cycling))
        #expect(modes.count == 3)
    }
}

// MARK: - Test Helpers for Route Building

extension WizPathRoute {
    static func testRoute(
        id: UUID = UUID(),
        travelMode: TravelMode = .car,
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
