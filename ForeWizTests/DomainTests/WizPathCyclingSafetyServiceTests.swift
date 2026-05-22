import Foundation
import Testing
import CoreLocation
import WizPathKit
@testable import ForeWiz

@MainActor
@Suite("WizPathCyclingSafetyService Tests")
struct WizPathCyclingSafetyServiceTests {

    private let service = WizPathCyclingSafetyService.shared

    // MARK: - Wind Thresholds

    @Test("Wind thresholds are reasonable")
    func windThresholdsAreReasonable() {
        #expect(WizPathCyclingSafetyService.WindThresholds.crosswindHazard == 25)
        #expect(WizPathCyclingSafetyService.WindThresholds.crosswindDangerous == 40)
        #expect(WizPathCyclingSafetyService.WindThresholds.headwindSignificant == 20)
        #expect(WizPathCyclingSafetyService.WindThresholds.headwindExtreme == 45)
    }

    // MARK: - Effort Level

    @Test("Effort level low for calm conditions")
    func effortLevelLowForCalmConditions() {
        let effort = WizPathCyclingSafetyService.EffortLevel.compute(
            windSpeed: 5,
            isHeadwind: false,
            temperature: 22,
            distance: 10000
        )
        #expect(effort.level <= 3)
        #expect(effort.extraTimePercent == 0)
    }

    @Test("Effort level moderate for moderate wind")
    func effortLevelModerateForModerateWind() {
        let effort = WizPathCyclingSafetyService.EffortLevel.compute(
            windSpeed: 15,
            isHeadwind: true,
            temperature: 22,
            distance: 10000
        )
        #expect(effort.level > 3, "Level should be > 3 for moderate effort")
        #expect(effort.level <= 6, "Level should be <= 6 for moderate effort")
        #expect(effort.extraTimePercent > 0, "Extra time should be > 0 for headwind")
    }

    @Test("Effort level high for strong headwind")
    func effortLevelHighForStrongHeadwind() {
        let effort = WizPathCyclingSafetyService.EffortLevel.compute(
            windSpeed: 40,
            isHeadwind: true,
            temperature: 22,
            distance: 10000
        )
        #expect(effort.level >= 7)
        #expect(effort.extraTimePercent > 10)
    }

    @Test("Effort level penalizes extreme temperatures")
    func effortLevelPenalizesExtremeTemperatures() {
        let hotEffort = WizPathCyclingSafetyService.EffortLevel.compute(
            windSpeed: 10,
            isHeadwind: false,
            temperature: 35,
            distance: 10000
        )
        let coldEffort = WizPathCyclingSafetyService.EffortLevel.compute(
            windSpeed: 10,
            isHeadwind: false,
            temperature: -5,
            distance: 10000
        )
        let comfortableEffort = WizPathCyclingSafetyService.EffortLevel.compute(
            windSpeed: 10,
            isHeadwind: false,
            temperature: 22,
            distance: 10000
        )
        #expect(hotEffort.level > comfortableEffort.level)
        #expect(coldEffort.level > comfortableEffort.level)
    }

    // MARK: - Cycling Safety Analysis

    @Test("AnalyzeCyclingSafety returns safe for non-cycling mode")
    func analyzeCyclingSafetyReturnsSafeForNonCyclingMode() {
        let route = makeRoute(travelMode: .car, segments: [
            makeSegment(weather: SegmentWeather(
                condition: .clear, temperature: 22, precipitationChance: 0,
                windSpeed: 5, visibility: 10, severity: .good
            ))
        ])
        let analysis = service.analyzeCyclingSafety(route: route)
        #expect(analysis.safety == WizPathCyclingSafetyService.CyclingSafety.safe)
        #expect(!analysis.hasCrosswindRisk)
        #expect(!analysis.hasSignificantHeadwind)
    }

    @Test("AnalyzeCyclingSafety detects crosswind hazard")
    func analyzeCyclingSafetyDetectsCrosswindHazard() {
        let route = makeRoute(travelMode: .cycling, segments: [
            makeSegment(weather: SegmentWeather(
                condition: .windy, temperature: 20, precipitationChance: 0,
                windSpeed: 30, visibility: 10, severity: .fair
            ))
        ])
        let analysis = service.analyzeCyclingSafety(route: route)
        #expect(analysis.hasCrosswindRisk)
        #expect(analysis.crosswindSegments.count > 0)
        #expect(analysis.maxGustSpeed >= 30)
    }

    @Test("AnalyzeCyclingSafety returns notRecommended for dangerous wind")
    func analyzeCyclingSafetyReturnsNotRecommendedForDangerousWind() {
        let route = makeRoute(travelMode: .cycling, segments: [
            makeSegment(weather: SegmentWeather(
                condition: .thunderstorm, temperature: 20, precipitationChance: 0.5,
                windSpeed: 50, visibility: 5, severity: .severe
            ))
        ])
        let analysis = service.analyzeCyclingSafety(route: route)
        if case WizPathCyclingSafetyService.CyclingSafety.notRecommended = analysis.safety {
            #expect(true)
        } else {
            #expect(Bool(false), "Expected .notRecommended but got \(analysis.safety)")
        }
    }

    @Test("AnalyzeCyclingSafety returns caution for moderate wind")
    func analyzeCyclingSafetyReturnsCautionForModerateWind() {
        let route = makeRoute(travelMode: .cycling, segments: [
            makeSegment(weather: SegmentWeather(
                condition: .windy, temperature: 20, precipitationChance: 0,
                windSpeed: 28, visibility: 10, severity: .fair
            ))
        ])
        let analysis = service.analyzeCyclingSafety(route: route)
        #expect(analysis.safety.isRisky)
        #expect(analysis.hasCrosswindRisk)
    }

    @Test("AnalyzeCyclingSafety computes effort correctly")
    func analyzeCyclingSafetyComputesEffortCorrectly() {
        let route = makeRoute(travelMode: .cycling, segments: [
            makeSegment(weather: SegmentWeather(
                condition: .windy, temperature: 20, precipitationChance: 0,
                windSpeed: 25, visibility: 10, severity: .fair
            ))
        ])
        let analysis = service.analyzeCyclingSafety(route: route)
        #expect(analysis.effortLevel.level >= 1)
        #expect(analysis.effortLevel.level <= 10)
    }

    @Test("AnalyzeCyclingSafety wind speed aggregation")
    func analyzeCyclingSafetyWindSpeedAggregation() {
        let route = makeRoute(travelMode: .cycling, segments: [
            makeSegment(weather: SegmentWeather(
                condition: .windy, temperature: 20, precipitationChance: 0,
                windSpeed: 20, visibility: 10, severity: .fair
            )),
            makeSegment(weather: SegmentWeather(
                condition: .windy, temperature: 20, precipitationChance: 0,
                windSpeed: 40, visibility: 8, severity: .fair
            )),
        ])
        let analysis = service.analyzeCyclingSafety(route: route)
        #expect(analysis.maxGustSpeed == 40)
        #expect(analysis.overallWindSpeed == 30)
    }

    @Test("EffortLevel struct properties")
    func effortLevelStructProperties() {
        let effort = WizPathCyclingSafetyService.EffortLevel(
            level: 5,
            title: "Moderate",
            description: "Test description",
            extraTimePercent: 15
        )
        #expect(effort.level == 5)
        #expect(effort.title == "Moderate")
        #expect(effort.description == "Test description")
        #expect(effort.extraTimePercent == 15)
    }

    @Test("CyclingWindSegment creation")
    func cyclingWindSegmentCreation() {
        let now = Date()
        let segment = WizPathCyclingSafetyService.CyclingWindSegment(
            segmentIndex: 2,
            windSpeed: 35.5,
            isHeadwind: true,
            eta: now
        )
        #expect(segment.segmentIndex == 2)
        #expect(segment.windSpeed == 35.5)
        #expect(segment.isHeadwind == true)
        #expect(segment.eta == now)
    }

    // MARK: - Helpers

    private func makeRoute(travelMode: TravelMode, segments: [WizPathSegment]) -> WizPathRoute {
        WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: travelMode,
            departureTime: Date(),
            segments: segments,
            totalDuration: 600,
            totalDistance: 10000,
            polyline: nil
        )
    }

    private func makeSegment(weather: SegmentWeather) -> WizPathSegment {
        WizPathSegment(
            id: UUID(),
            coordinate: CLLocationCoordinate2D(latitude: 41.5, longitude: 29.5),
            estimatedArrival: Date(),
            distanceFromStart: 5000,
            travelTime: 300,
            weather: weather
        )
    }
}
