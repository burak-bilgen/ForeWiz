import Foundation
import Testing
import WizPathKit
@testable import ForeWiz

@Suite("LiveActivity Widget Extension Tests")
struct LiveActivityWidgetExtensionTests {

    private func safetyColor(_ score: Int) -> String {
        switch score {
        case 80...100: return "green"
        case 60..<80: return "yellow"
        case 40..<60: return "orange"
        default: return "red"
        }
    }

    @Test("safetyColor returns green for 80-100 range")
    func safetyColorGreenRange() async throws {
        #expect(safetyColor(80) == "green")
        #expect(safetyColor(90) == "green")
        #expect(safetyColor(100) == "green")
    }

    @Test("safetyColor returns yellow for 60-79 range")
    func safetyColorYellowRange() async throws {
        #expect(safetyColor(60) == "yellow")
        #expect(safetyColor(70) == "yellow")
        #expect(safetyColor(79) == "yellow")
    }

    @Test("safetyColor returns orange for 40-59 range")
    func safetyColorOrangeRange() async throws {
        #expect(safetyColor(40) == "orange")
        #expect(safetyColor(50) == "orange")
        #expect(safetyColor(59) == "orange")
    }

    @Test("safetyColor returns red for 0-39 range")
    func safetyColorRedRange() async throws {
        #expect(safetyColor(0) == "red")
        #expect(safetyColor(20) == "red")
        #expect(safetyColor(39) == "red")
    }

    @Test("safetyColor handles edge values correctly")
    func safetyColorEdgeValues() async throws {
        #expect(safetyColor(80) == "green")
        #expect(safetyColor(60) == "yellow")
        #expect(safetyColor(40) == "orange")
        #expect(safetyColor(0) == "red")
    }

    private func hazardColor(_ count: Int) -> String {
        count == 0 ? "green" : count <= 3 ? "yellow" : "red"
    }

    @Test("hazardColor returns green for 0 hazards")
    func hazardColorNoHazards() async throws {
        #expect(hazardColor(0) == "green")
    }

    @Test("hazardColor returns yellow for 1-3 hazards")
    func hazardColorFewHazards() async throws {
        for count in 1...3 {
            #expect(hazardColor(count) == "yellow")
        }
    }

    @Test("hazardColor returns red for 4+ hazards")
    func hazardColorManyHazards() async throws {
        #expect(hazardColor(4) == "red")
        #expect(hazardColor(10) == "red")
        #expect(hazardColor(100) == "red")
    }

    private func widgetTravelModeIcon(_ rawValue: String) -> String {
        switch rawValue {
        case "car": return "car.fill"
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "transit": return "bus.fill"
        default: return "car.fill"
        }
    }

    @Test("travelModeIcon returns correct icons for all modes")
    func travelModeIconAllModes() async throws {
        #expect(widgetTravelModeIcon("car") == "car.fill")
        #expect(widgetTravelModeIcon("walking") == "figure.walk")
        #expect(widgetTravelModeIcon("cycling") == "bicycle")
        #expect(widgetTravelModeIcon("transit") == "bus.fill")
    }

    @Test("travelModeIcon falls back to car for unknown mode")
    func travelModeIconFallback() async throws {
        #expect(widgetTravelModeIcon("") == "car.fill")
        #expect(widgetTravelModeIcon("scooter") == "car.fill")
        #expect(widgetTravelModeIcon("unknown") == "car.fill")
    }

    @available(iOS 18.0, *)
    @Test("ContentState with no hazards shows clear state")
    func contentStateNoHazards() async throws {
        let state = WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: 92,
            hazardCount: 0,
            totalDuration: 2400,
            distanceRemaining: 35000,
            nextSafeStopName: nil,
            nextSafeStopEta: nil,
            routeRiskLabel: "Good",
            weatherConditionSymbol: "sun.max.fill",
            estimatedArrival: Date().addingTimeInterval(2400)
        )

        #expect(state.hazardCount == 0)
        #expect(state.nextSafeStopName == nil)
        #expect(state.safetyScore >= 80)
    }

    @available(iOS 18.0, *)
    @Test("ContentState with multiple hazards and next safe stop")
    func contentStateWithSafeStop() async throws {
        let eta = Date().addingTimeInterval(1200)
        let state = WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: 45,
            hazardCount: 5,
            totalDuration: 5400,
            distanceRemaining: 80000,
            nextSafeStopName: "Gas Station",
            nextSafeStopEta: eta,
            routeRiskLabel: "Caution",
            weatherConditionSymbol: "cloud.rain.fill",
            estimatedArrival: Date().addingTimeInterval(5400)
        )

        #expect(state.safetyScore == 45)
        #expect(state.hazardCount == 5)
        #expect(state.nextSafeStopName == "Gas Station")
        #expect(state.nextSafeStopEta == eta)
        #expect(state.routeRiskLabel == "Caution")
    }

    @available(iOS 18.0, *)
    @Test("ContentState with zero safety score shows emergency state")
    func contentStateEmergency() async throws {
        let state = WizPathHUDLiveActivityAttributes.ContentState(
            safetyScore: 0,
            hazardCount: 15,
            totalDuration: 0,
            distanceRemaining: 0,
            nextSafeStopName: nil,
            nextSafeStopEta: nil,
            routeRiskLabel: "Emergency",
            weatherConditionSymbol: "exclamationmark.triangle.fill",
            estimatedArrival: Date()
        )

        #expect(state.safetyScore == 0)
        #expect(state.hazardCount == 15)
        #expect(state.routeRiskLabel == "Emergency")
    }
}
