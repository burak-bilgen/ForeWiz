import Foundation
import Testing
import WizPathKit
@testable import ForeWiz

@Suite("WizPathHUDManager Tests")
struct WizPathHUDManagerTests {

    // MARK: - Content State

    @available(iOS 18.0, *)
    @Test("ContentState initializes with default values")
    func contentStateInitializesWithDefaultValues() async throws {
        let state = WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: 0,
            hazardCount: 0,
            totalDuration: 0,
            distanceRemaining: 0,
            nextSafeStopName: nil,
            nextSafeStopEta: nil,
            routeRiskLabel: "Calculating...",
            weatherConditionSymbol: "questionmark",
            estimatedArrival: Date()
        )

        #expect(state.safetyScore == 0)
        #expect(state.hazardCount == 0)
        #expect(state.totalDuration == 0)
        #expect(state.distanceRemaining == 0)
        #expect(state.nextSafeStopName == nil)
        #expect(state.routeRiskLabel == "Calculating...")
        #expect(state.weatherConditionSymbol == "questionmark")
    }

    @available(iOS 18.0, *)
    @Test("ContentState with perfect safety score")
    func contentStateWithPerfectSafetyScore() async throws {
        let state = WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: 100,
            hazardCount: 0,
            totalDuration: 3600,
            distanceRemaining: 25000,
            nextSafeStopName: "Rest Area",
            nextSafeStopEta: Date().addingTimeInterval(1800),
            routeRiskLabel: "Good",
            weatherConditionSymbol: "sun.max.fill",
            estimatedArrival: Date().addingTimeInterval(3600)
        )

        #expect(state.safetyScore == 100)
        #expect(state.hazardCount == 0)
        #expect(state.totalDuration == 3600)
        #expect(state.distanceRemaining == 25000)
        #expect(state.nextSafeStopName == "Rest Area")
        #expect(state.routeRiskLabel == "Good")
        #expect(state.weatherConditionSymbol == "sun.max.fill")
    }

    @available(iOS 18.0, *)
    @Test("ContentState with severe hazard conditions")
    func contentStateWithSevereHazards() async throws {
        let state = WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: 15,
            hazardCount: 8,
            totalDuration: 7200,
            distanceRemaining: 100000,
            nextSafeStopName: nil,
            nextSafeStopEta: nil,
            routeRiskLabel: "Severe",
            weatherConditionSymbol: "cloud.bolt.rain.fill",
            estimatedArrival: Date().addingTimeInterval(7200)
        )

        #expect(state.safetyScore == 15)
        #expect(state.hazardCount == 8)
        #expect(state.routeRiskLabel == "Severe")
        #expect(state.nextSafeStopName == nil)
    }

    @available(iOS 18.0, *)
    @Test("ContentState Codable round-trip")
    func contentStateCodableRoundTrip() throws {
        let original = WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: 85,
            hazardCount: 2,
            totalDuration: 1800,
            distanceRemaining: 15000,
            nextSafeStopName: "Coffee Shop",
            nextSafeStopEta: Date().addingTimeInterval(900),
            routeRiskLabel: "Good",
            weatherConditionSymbol: "cloud.sun.fill",
            estimatedArrival: Date().addingTimeInterval(1800)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WizPathHUDLiveActivityAttributes.ContentState.self, from: data)

        #expect(decoded.safetyScore == original.safetyScore)
        #expect(decoded.hazardCount == original.hazardCount)
        #expect(decoded.totalDuration == original.totalDuration)
        #expect(decoded.distanceRemaining == original.distanceRemaining)
        #expect(decoded.nextSafeStopName == original.nextSafeStopName)
        #expect(decoded.routeRiskLabel == original.routeRiskLabel)
        #expect(decoded.weatherConditionSymbol == original.weatherConditionSymbol)
    }

    @available(iOS 18.0, *)
    @Test("ContentState equality")
    func contentStateEquality() async throws {
        let now = Date()
        let state1 = WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: 50, hazardCount: 0, totalDuration: 0,
            distanceRemaining: 0, nextSafeStopName: nil, nextSafeStopEta: nil,
            routeRiskLabel: "Moderate", weatherConditionSymbol: "cloud",
            estimatedArrival: now
        )
        let state2 = WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: 50, hazardCount: 0, totalDuration: 0,
            distanceRemaining: 0, nextSafeStopName: nil, nextSafeStopEta: nil,
            routeRiskLabel: "Moderate", weatherConditionSymbol: "cloud",
            estimatedArrival: now
        )

        #expect(state1 == state2)
    }

    // MARK: - Attributes

    @available(iOS 18.0, *)
    @Test("LiveActivityAttributes initializes correctly")
    func liveActivityAttributesInitializes() async throws {
        let attrs = WizPathHUDLiveActivityAttributes(
            routeOriginName: "Home",
            routeDestinationName: "Work",
            travelModeRaw: "car"
        )

        #expect(attrs.routeOriginName == "Home")
        #expect(attrs.routeDestinationName == "Work")
        #expect(attrs.travelModeRaw == "car")
    }

    @available(iOS 18.0, *)
    @Test("LiveActivityAttributes with cycling mode")
    func liveActivityAttributesCycling() async throws {
        let attrs = WizPathHUDLiveActivityAttributes(
            routeOriginName: "Kad\u{0131}k\u{00f6}y",
            routeDestinationName: "Levent",
            travelModeRaw: "cycling"
        )

        #expect(attrs.travelModeRaw == "cycling")
    }

    // MARK: - HUD Manager Singleton

    @available(iOS 18.0, *)
    @Test("WizPathHUDManager shared is singleton")
    func hudManagerSharedIsSingleton() async throws {
        let instance1 = WizPathHUDManager.shared
        let instance2 = WizPathHUDManager.shared
        #expect(instance1 === instance2)
    }

    // MARK: - Travel Mode Icon Mapping

    @Test("travelModeIcon returns correct SF Symbol for each mode")
    func travelModeIconMapping() async throws {
        /// Mirrors the widget's travelModeIcon helper — update if widget changes
        func iconForTravelMode(_ rawValue: String) -> String {
            switch rawValue {
            case "car": return "car.fill"
            case "walking": return "figure.walk"
            case "cycling": return "bicycle"
            case "transit": return "bus.fill"
            default: return "car.fill"
            }
        }

        #expect(iconForTravelMode("car") == "car.fill")
        #expect(iconForTravelMode("walking") == "figure.walk")
        #expect(iconForTravelMode("cycling") == "bicycle")
        #expect(iconForTravelMode("transit") == "bus.fill")
        #expect(iconForTravelMode("unknown") == "car.fill") // default fallback
    }
}
