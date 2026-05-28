import Foundation
import Testing
import CoreLocation
import MapKit
@testable import WizPathKit
@testable import ForeWiz

@Suite("EV Range & Charging Planning Tests")
struct EvRangePlanningTests {
    
    // Helper to generate a mock route for testing
    private func makeMockRoute(
        mode: TravelMode = .car,
        distance: Double = 100_000, // 100 km
        duration: Double = 3600,   // 1 hour (100 km/h)
        weather: SegmentWeather? = nil
    ) -> WizPathRoute {
        let segments = (0..<10).map { i -> WizPathSegment in
            WizPathSegment(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 41.0 + Double(i)*0.01, longitude: 29.0 + Double(i)*0.01),
                estimatedArrival: Date().addingTimeInterval(Double(i) * (duration / 10.0)),
                distanceFromStart: Double(i) * (distance / 10.0),
                travelTime: duration / 10.0,
                weather: weather ?? SegmentWeather(
                    condition: .clear,
                    temperature: 20, // perfect temperature (no penalty)
                    precipitationChance: 0,
                    windSpeed: 0,
                    visibility: 10,
                    severity: .good
                )
            )
        }
        
        return WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 41.1, longitude: 29.1),
            travelMode: mode,
            departureTime: Date(),
            segments: segments,
            totalDuration: duration,
            totalDistance: distance,
            polyline: nil
        )
    }

    @Test("EV Range Service calculates correct base consumption without penalties")
    func baseConsumptionWithoutPenalties() async throws {
        let route = makeMockRoute(distance: 100_000, duration: 3600) // 100km at 100km/h
        
        let estimate = await EvRangeService.shared.estimateRange(
            for: route,
            baseRangeKm: 400.0, // base 18.75 kWh / 100km
            batteryCapacityKwh: 75.0,
            startingChargePercent: 80.0
        )
        
        // 100 km distance on 400 km base range with elevation recovery
        #expect(estimate.baseRangeKm == 400.0)
        #expect(abs(estimate.adjustedRangeKm - 408.16) < 0.1)
        #expect(abs(estimate.consumptionWhPerKm - 183.75) < 0.1)
    }

    @Test("EV Range Service applies correct cold weather and wind penalties")
    func weatherPenaltiesApplied() async throws {
        let extremeWeather = SegmentWeather(
            condition: .rain,
            temperature: -5, // cold weather battery penalty
            precipitationChance: 0.8, // precipitation rolling resistance penalty
            windSpeed: 30, // wind resistance penalty
            visibility: 5,
            severity: .caution
        )
        let route = makeMockRoute(weather: extremeWeather)
        
        let estimate = await EvRangeService.shared.estimateRange(
            for: route,
            baseRangeKm: 400.0,
            batteryCapacityKwh: 75.0,
            startingChargePercent: 80.0
        )
        
        // Adjusted range should be smaller than base due to penalties
        #expect(estimate.adjustedRangeKm < estimate.baseRangeKm)
        #expect(estimate.consumptionWhPerKm > 187.5) // consumption increases
        
        // Ensure segments contain temperature, wind, and precipitation factors
        if let segment = estimate.segments.first {
            #expect(segment.factors.contains { if case .temperature = $0 { return true }; return false })
            #expect(segment.factors.contains { if case .wind = $0 { return true }; return false })
            #expect(segment.factors.contains { if case .precipitation = $0 { return true }; return false })
        }
    }

    @Test("EV Range Service applies high-speed drag penalties")
    func highSpeedPenaltyApplied() async throws {
        // 100 km in 30 minutes = 200 km/h average speed (highway speed penalty)
        let route = makeMockRoute(distance: 100_000, duration: 1800)
        
        let estimate = await EvRangeService.shared.estimateRange(
            for: route,
            baseRangeKm: 400.0,
            batteryCapacityKwh: 75.0,
            startingChargePercent: 80.0
        )
        
        #expect(estimate.adjustedRangeKm < estimate.baseRangeKm)
        if let segment = estimate.segments.first {
            #expect(segment.factors.contains { if case .generalHighSpeed = $0 { return true }; return false })
        }
    }

    @Test("EV Charging Stop Planner schedules chargers when charge falls below threshold")
    func chargingStopsScheduled() async throws {
        // High consumption route that consumes more than initial charge (80% of 75 kWh = 60 kWh)
        // Let's plan a 400 km route. At base rate, it consumes 75 kWh (100% of battery).
        let longRoute = makeMockRoute(distance: 400_000, duration: 14400) // 400 km
        
        // Place some chargers along the route segments coordinates
        let charger1Coord = longRoute.segments[3].coordinate
        let charger2Coord = longRoute.segments[7].coordinate
        
        let chargers = [
            SmartStop(
                id: UUID(),
                mapItem: MKMapItem(placemark: MKPlacemark(coordinate: charger1Coord)),
                coordinate: charger1Coord,
                name: "Supercharger A",
                category: .evCharger,
                etaArrival: Date(),
                weatherAtArrival: nil,
                safetyStatus: .safe,
                distanceFromRoute: 50.0,
                estimatedStopDuration: 1800
            ),
            SmartStop(
                id: UUID(),
                mapItem: MKMapItem(placemark: MKPlacemark(coordinate: charger2Coord)),
                coordinate: charger2Coord,
                name: "Supercharger B",
                category: .evCharger,
                etaArrival: Date(),
                weatherAtArrival: nil,
                safetyStatus: .safe,
                distanceFromRoute: 80.0,
                estimatedStopDuration: 1800
            )
        ]
        
        let plan = await EvChargingPlannerService.shared.planChargingStops(
            for: longRoute,
            chargers: chargers,
            batteryCapacityKwh: 75.0,
            startingChargePercent: 80.0,
            thresholdPercent: 15.0
        )
        
        // It must schedule at least 1 charging stop to complete a 400km journey safely
        #expect(!plan.stops.isEmpty)
        #expect(plan.totalChargingTime > 0)
        #expect(plan.totalCost > 0)
        #expect(plan.routeImpact > 0)
        #expect(plan.destinationChargePercent >= 15.0)
    }

    @Test("EV Charging Stop Planner bypasses non-car travel modes")
    func bypassNonCarModes() async throws {
        let route = makeMockRoute(mode: .cycling, distance: 30_000, duration: 7200)
        
        let plan = await EvChargingPlannerService.shared.planChargingStops(
            for: route,
            chargers: [],
            batteryCapacityKwh: 75.0,
            startingChargePercent: 80.0
        )
        
        #expect(plan.stops.isEmpty)
        #expect(plan.totalChargingTime == 0)
    }
}
