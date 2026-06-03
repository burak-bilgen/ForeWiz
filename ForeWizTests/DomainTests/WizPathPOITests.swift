import Foundation
import Testing
import CoreLocation
@preconcurrency import MapKit
import WizPathKit
@testable import ForeWiz

@MainActor
@Suite("WizPath POI & Hazard Tests")
struct WizPathPOITests {

    // MARK: - POICategory Tests

    @Test("POICategory enum cases")
    func poiCategoryEnumCases() async throws {
        #expect(POICategory.gasStation.rawValue == "gasStation")
        #expect(POICategory.restStop.rawValue == "restStop")
        #expect(POICategory.restaurant.rawValue == "restaurant")
        #expect(POICategory.evCharger.rawValue == "evCharger")
    }

    @Test("POICategory icon names")
    func poiCategoryIconNames() async throws {
        #expect(POICategory.gasStation.iconName == "fuelpump.fill")
        #expect(POICategory.restStop.iconName == "bed.double.fill")
        #expect(POICategory.restaurant.iconName == "fork.knife")
        #expect(POICategory.evCharger.iconName == "bolt.car.fill")
    }

    @Test("POICategory default names are non-empty")
    func poiCategoryDefaultNames() async throws {
        #expect(!POICategory.gasStation.defaultName.isEmpty)
        #expect(!POICategory.restStop.defaultName.isEmpty)
        #expect(!POICategory.restaurant.defaultName.isEmpty)
        #expect(!POICategory.evCharger.defaultName.isEmpty)
    }

    @Test("POICategory colors")
    func poiCategoryColors() async throws {
        #expect(POICategory.gasStation.color == "#00FF41")
        #expect(POICategory.restStop.color == "#FF9500")
        #expect(POICategory.restaurant.color == "#FF3BFF")
        #expect(POICategory.evCharger.color == "#00D9FF")
    }

    @Test("POICategory mkCategory returns correct MapKit category")
    func poiCategoryMkCategory() async throws {
        #expect(POICategory.gasStation.mkCategory == MKPointOfInterestCategory.gasStation)
        #expect(POICategory.restStop.mkCategory == nil)
        #expect(POICategory.restaurant.mkCategory == MKPointOfInterestCategory.restaurant)
        #expect(POICategory.evCharger.mkCategory == MKPointOfInterestCategory.evCharger)
    }

    // MARK: - POISafetyStatus Tests

    @Test("POISafetyStatus enum values")
    func poiSafetyStatusEnumValues() async throws {
        #expect(POISafetyStatus.safe.rawValue == "safe")
        #expect(POISafetyStatus.caution.rawValue == "caution")
        #expect(POISafetyStatus.unsafe.rawValue == "unsafe")
        #expect(POISafetyStatus.dangerous.rawValue == "dangerous")
    }

    @Test("POISafetyStatus shouldAvoid")
    func poiSafetyStatusShouldAvoid() async throws {
        #expect(POISafetyStatus.safe.shouldAvoid == false)
        #expect(POISafetyStatus.caution.shouldAvoid == false)
        #expect(POISafetyStatus.unsafe.shouldAvoid == true)
        #expect(POISafetyStatus.dangerous.shouldAvoid == true)
    }

    @Test("POISafetyStatus localized titles")
    func poiSafetyStatusLocalizedTitles() async throws {
        #expect(!POISafetyStatus.safe.localizedTitle.isEmpty)
        #expect(!POISafetyStatus.caution.localizedTitle.isEmpty)
        #expect(!POISafetyStatus.unsafe.localizedTitle.isEmpty)
        #expect(!POISafetyStatus.dangerous.localizedTitle.isEmpty)
    }

    // MARK: - SmartStop Tests

    private func makeMapItem() -> MKMapItem {
        MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0)))
    }

    @Test("SmartStop displayTitle uses name when available")
    func smartStopDisplayTitleUsesName() async throws {
        let mapItem = makeMapItem()
        let stop = SmartStop(
            id: UUID(),
            mapItem: mapItem,
            coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            name: "Test Station",
            category: .gasStation,
            etaArrival: Date(),
            weatherAtArrival: nil,
            safetyStatus: .safe,
            distanceFromRoute: 1000,
            estimatedStopDuration: 1800
        )
        #expect(stop.displayTitle == "Test Station")
    }

    @Test("SmartStop displayTitle falls back to category default")
    func smartStopDisplayTitleFallsBackToCategoryDefault() async throws {
        let mapItem = makeMapItem()
        let stop = SmartStop(
            id: UUID(),
            mapItem: mapItem,
            coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            name: "",
            category: .gasStation,
            etaArrival: Date(),
            weatherAtArrival: nil,
            safetyStatus: .safe,
            distanceFromRoute: 1000,
            estimatedStopDuration: 1800
        )
        #expect(stop.displayTitle == POICategory.gasStation.defaultName)
    }

    @Test("SmartStop isRecommended for safe/caution")
    func smartStopIsRecommended() async throws {
        let mapItem = makeMapItem()
        let safe = SmartStop(id: UUID(), mapItem: mapItem, coordinate: .init(latitude: 41, longitude: 29), name: "Safe", category: .restStop, etaArrival: Date(), weatherAtArrival: nil, safetyStatus: .safe, distanceFromRoute: 0, estimatedStopDuration: 1800)
        let unsafe = SmartStop(id: UUID(), mapItem: mapItem, coordinate: .init(latitude: 41, longitude: 29), name: "Unsafe", category: .restStop, etaArrival: Date(), weatherAtArrival: nil, safetyStatus: .unsafe, distanceFromRoute: 0, estimatedStopDuration: 1800)
        #expect(safe.isRecommended == true)
        #expect(unsafe.isRecommended == false)
    }

    @Test("SmartStop etaDisplay format")
    func smartStopEtaDisplay() async throws {
        let mapItem = makeMapItem()
        let stop = SmartStop(id: UUID(), mapItem: mapItem, coordinate: .init(latitude: 41, longitude: 29), name: "Test", category: .restaurant, etaArrival: Date(), weatherAtArrival: nil, safetyStatus: .safe, distanceFromRoute: 0, estimatedStopDuration: 1800)
        #expect(!stop.etaDisplay.isEmpty)
    }

    // MARK: - HazardType Tests

    @Test("HazardType enum cases")
    func hazardTypeEnumCases() async throws {
        #expect(HazardType.crosswind.rawValue == "crosswind")
        #expect(HazardType.sunGlare.rawValue == "sunGlare")
        #expect(HazardType.heavyRain.rawValue == "heavyRain")
        #expect(HazardType.snow.rawValue == "snow")
        #expect(HazardType.thunderstorm.rawValue == "thunderstorm")
        #expect(HazardType.fog.rawValue == "fog")
        #expect(HazardType.ice.rawValue == "ice")
    }

    @Test("HazardType icon names")
    func hazardTypeIconNames() async throws {
        #expect(HazardType.crosswind.iconName == "wind")
        #expect(HazardType.sunGlare.iconName == "sun.max")
        #expect(HazardType.heavyRain.iconName == "cloud.heavyrain.fill")
        #expect(HazardType.snow.iconName == "snowflake")
        #expect(HazardType.thunderstorm.iconName == "cloud.bolt.fill")
        #expect(HazardType.fog.iconName == "cloud.fog.fill")
        #expect(HazardType.ice.iconName == "thermometer.snowflake")
    }

    @Test("HazardType localized titles are non-empty")
    func hazardTypeLocalizedTitles() async throws {
        #expect(!HazardType.crosswind.localizedTitle.isEmpty)
        #expect(!HazardType.sunGlare.localizedTitle.isEmpty)
        #expect(!HazardType.heavyRain.localizedTitle.isEmpty)
        #expect(!HazardType.snow.localizedTitle.isEmpty)
        #expect(!HazardType.thunderstorm.localizedTitle.isEmpty)
        #expect(!HazardType.fog.localizedTitle.isEmpty)
        #expect(!HazardType.ice.localizedTitle.isEmpty)
    }

    @Test("HazardType vehicle types affected")
    func hazardTypeVehicleTypesAffected() async throws {
        #expect(HazardType.crosswind.vehicleTypesAffected.contains(.car))
        #expect(HazardType.crosswind.vehicleTypesAffected.contains(.walking))
        #expect(HazardType.sunGlare.vehicleTypesAffected.contains(.car))
        #expect(HazardType.sunGlare.vehicleTypesAffected.count == 1)
        #expect(HazardType.ice.vehicleTypesAffected.contains(.car))
        #expect(HazardType.ice.vehicleTypesAffected.contains(.walking))
    }

    // MARK: - HazardSeverity Tests

    @Test("HazardSeverity enum values")
    func hazardSeverityEnumValues() async throws {
        #expect(HazardSeverity.low.rawValue == "low")
        #expect(HazardSeverity.moderate.rawValue == "moderate")
        #expect(HazardSeverity.high.rawValue == "high")
        #expect(HazardSeverity.critical.rawValue == "critical")
    }

    @Test("HazardSeverity colors")
    func hazardSeverityColors() async throws {
        #expect(HazardSeverity.low.color == "#00FF41")
        #expect(HazardSeverity.moderate.color == "#FFCC00")
        #expect(HazardSeverity.high.color == "#FF9500")
        #expect(HazardSeverity.critical.color == "#FF3B30")
    }

    @Test("HazardSeverity localized titles")
    func hazardSeverityLocalizedTitles() async throws {
        #expect(!HazardSeverity.low.localizedTitle.isEmpty)
        #expect(!HazardSeverity.moderate.localizedTitle.isEmpty)
        #expect(!HazardSeverity.high.localizedTitle.isEmpty)
        #expect(!HazardSeverity.critical.localizedTitle.isEmpty)
    }

    // MARK: - EnvironmentalHazard Tests

    @Test("EnvironmentalHazard properties")
    func environmentalHazardProperties() async throws {
        let hazard = EnvironmentalHazard(
            id: UUID(),
            type: .crosswind,
            coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            routeSegmentIndex: 2,
            severity: .high,
            details: "Strong crosswind detected",
            recommendation: "Reduce speed",
            etaAtLocation: Date()
        )
        #expect(hazard.type == .crosswind)
        #expect(hazard.routeSegmentIndex == 2)
        #expect(hazard.severity == .high)
        #expect(hazard.details == "Strong crosswind detected")
        #expect(!hazard.localizedTitle.isEmpty)
        #expect(!hazard.iconName.isEmpty)
    }

    // MARK: - JourneyHUDData Tests

    @Test("JourneyHUDData duration display")
    func journeyHUDDataDurationDisplay() async throws {
        let hud = JourneyHUDData(
            totalDuration: 3660, // 1h 1m
            totalDistance: 30000,
            hazardCount: 2,
            safeStops: 3,
            safetyScore: 75,
            activeHazards: [],
            nextSafeStop: nil
        )
        #expect(!hud.durationDisplay.isEmpty)
        #expect(hud.safetyScore == 75)
        #expect(hud.hazardCount == 2)
        #expect(hud.safeStops == 3)
    }

    @Test("JourneyHUDData duration display for short trips")
    func journeyHUDDataDurationDisplayForShortTrips() async throws {
        let hud = JourneyHUDData(
            totalDuration: 600, // 10 min
            totalDistance: 5000,
            hazardCount: 0,
            safeStops: 0,
            safetyScore: 100,
            activeHazards: [],
            nextSafeStop: nil
        )
        #expect(!hud.durationDisplay.isEmpty)
    }

    @Test("JourneyHUDData with hazards")
    func journeyHUDDataWithHazards() async throws {
        let hazard = EnvironmentalHazard(
            id: UUID(),
            type: .thunderstorm,
            coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            routeSegmentIndex: 0,
            severity: .critical,
            details: "Thunderstorm ahead",
            recommendation: "Seek shelter",
            etaAtLocation: Date()
        )
        let hud = JourneyHUDData(
            totalDuration: 1800,
            totalDistance: 15000,
            hazardCount: 1,
            safeStops: 2,
            safetyScore: 50,
            activeHazards: [hazard],
            nextSafeStop: nil
        )
        #expect(hud.activeHazards.count == 1)
        #expect(hud.activeHazards.first?.type == .thunderstorm)
    }
}
