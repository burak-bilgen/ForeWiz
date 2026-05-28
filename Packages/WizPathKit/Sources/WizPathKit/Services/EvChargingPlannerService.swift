import Foundation
import CoreLocation

public struct EvChargingPlan: Sendable {
    public let stops: [ChargingStop]
    public let totalChargingTime: TimeInterval
    public let totalCost: Double
    public let routeImpact: TimeInterval // Time added compared to a non-stop journey (charging time + detour overhead)
    public let destinationChargePercent: Double
}

public struct ChargingStop: Sendable, Equatable {
    public static func == (lhs: ChargingStop, rhs: ChargingStop) -> Bool {
        lhs.chargerStop == rhs.chargerStop &&
        lhs.arrivalChargePercent == rhs.arrivalChargePercent &&
        lhs.recommendedChargePercent == rhs.recommendedChargePercent &&
        lhs.estimatedChargeTime == rhs.estimatedChargeTime &&
        lhs.estimatedCost == rhs.estimatedCost &&
        lhs.recommendation == rhs.recommendation
    }
    public let chargerStop: SmartStop
    public let arrivalChargePercent: Double
    public let recommendedChargePercent: Double
    public let estimatedChargeTime: TimeInterval
    public let estimatedCost: Double
    public let recommendation: String
}

public final class EvChargingPlannerService: Sendable {
    public static let shared = EvChargingPlannerService()
    
    private init() {}
    
    /// Simulates driving and plans optimal EV charging stops along a route given the vehicle parameters.
    /// - Parameters:
    ///   - route: The route to analyze.
    ///   - chargers: A list of EV Charger POIs searched along the route.
    ///   - batteryCapacityKwh: The vehicle's battery capacity in kWh (default is 75 kWh).
    ///   - startingChargePercent: The starting charge level (0.0 to 100.0, default is 80.0).
    ///   - thresholdPercent: The battery percentage that triggers a charging stop recommendation (default is 15.0%).
    public func planChargingStops(
        for route: WizPathRoute,
        chargers: [SmartStop],
        batteryCapacityKwh: Double = 75.0,
        startingChargePercent: Double = 80.0,
        thresholdPercent: Double = 15.0
    ) async -> EvChargingPlan {
        guard route.travelMode == .car else {
            return EvChargingPlan(stops: [], totalChargingTime: 0, totalCost: 0, routeImpact: 0, destinationChargePercent: startingChargePercent)
        }
        
        let rangeEstimate = await EvRangeService.shared.estimateRange(
            for: route,
            baseRangeKm: (batteryCapacityKwh * 1000.0) / 180.0, // base 180 Wh/km
            batteryCapacityKwh: batteryCapacityKwh,
            startingChargePercent: startingChargePercent
        )
        
        var plannedStops: [ChargingStop] = []
        var currentChargePercent = startingChargePercent
        var totalChargingTime: TimeInterval = 0
        var totalCost: Double = 0
        
        let segmentDistanceKm = (route.totalDistance / Double(route.segments.count)) / 1000.0
        var remainingChargers = chargers.sorted { $0.distanceFromRoute < $1.distanceFromRoute }
        
        // Track the indices of segments where we plan a stop
        var currentSegmentIndex = 0
        while currentSegmentIndex < route.segments.count {
            let segmentRangeEst = rangeEstimate.segments[currentSegmentIndex]
            
            // Calculate battery percentage consumed on this segment
            let segmentConsumptionPercent = (segmentRangeEst.energyUsedKwh / batteryCapacityKwh) * 100.0
            currentChargePercent -= segmentConsumptionPercent
            
            // If battery drops below the threshold, plan a charging stop
            if currentChargePercent <= thresholdPercent {
                // Find a charger that is ahead of us along the route
                let segmentCoord = route.segments[currentSegmentIndex].coordinate
                let segmentLocation = CLLocation(latitude: segmentCoord.latitude, longitude: segmentCoord.longitude)
                
                // Find nearest charger ahead of us
                if let optimalCharger = remainingChargers.first(where: { charger in
                    let chargerLocation = CLLocation(latitude: charger.coordinate.latitude, longitude: charger.coordinate.longitude)
                    // Ensure the charger is close to this section of the route
                    return segmentLocation.distance(from: chargerLocation) < 25_000
                }) {
                    let arrivalCharge = max(2.0, currentChargePercent + 3.0) // assume slight recovery / detour arrival
                    
                    // We charge up to 80% (optimal fast charge curve range)
                    let targetCharge = 80.0
                    let energyToChargeKwh = ((targetCharge - arrivalCharge) / 100.0) * batteryCapacityKwh
                    
                    // Fast DC Charger averages 120kW charging speed
                    let chargingTimeSeconds = (energyToChargeKwh / 120.0) * 3600.0
                    
                    // Standard cost: $0.42 per kWh
                    let stopCost = energyToChargeKwh * 0.42
                    
                    let timeText = String(format: "%d min", Int(chargingTimeSeconds / 60.0))
                    let recommendation = WizPathKitL10n.formatted("ev_charge_recommendation", timeText, Int(arrivalCharge), Int(targetCharge))
                    
                    plannedStops.append(ChargingStop(
                        chargerStop: optimalCharger,
                        arrivalChargePercent: arrivalCharge,
                        recommendedChargePercent: targetCharge,
                        estimatedChargeTime: chargingTimeSeconds,
                        estimatedCost: stopCost,
                        recommendation: recommendation
                    ))
                    
                    totalChargingTime += chargingTimeSeconds
                    totalCost += stopCost
                    currentChargePercent = targetCharge
                    
                    // Remove the used charger from candidates
                    remainingChargers.removeAll { $0.id == optimalCharger.id }
                } else {
                    // No charger found, force charge recover representation to simulate driving continuation safely
                    currentChargePercent = 80.0
                }
            }
            
            currentSegmentIndex += 1
        }
        
        // Detour time overhead is approx 5 minutes (300 seconds) per stop
        let detourOverhead = Double(plannedStops.count) * 300.0
        let routeImpact = totalChargingTime + detourOverhead
        
        return EvChargingPlan(
            stops: plannedStops,
            totalChargingTime: totalChargingTime,
            totalCost: totalCost,
            routeImpact: routeImpact,
            destinationChargePercent: max(0.0, currentChargePercent)
        )
    }
}
