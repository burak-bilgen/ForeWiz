import Foundation
import CoreLocation

// MARK: - EV Charging Planner Protocol

/// Protocol for EV charging stop planners.
public protocol EvChargingPlannerServiceProtocol: AnyObject, Sendable {
    func planChargingStops(
        for route: WizPathRoute,
        chargers: [SmartStop],
        vehicle: VehicleModel,
        startingChargePercent: Double,
        thresholdPercent: Double
    ) async -> EvChargingPlan
}

public struct EvChargingPlan: Sendable {
    public let stops: [ChargingStop]
    public let totalChargingTime: TimeInterval
    public let totalCost: Double
    public let routeImpact: TimeInterval // Time added compared to a non-stop journey (charging time + detour overhead)
    public let destinationChargePercent: Double

    public init(stops: [ChargingStop], totalChargingTime: TimeInterval, totalCost: Double,
                routeImpact: TimeInterval, destinationChargePercent: Double) {
        self.stops = stops
        self.totalChargingTime = totalChargingTime
        self.totalCost = totalCost
        self.routeImpact = routeImpact
        self.destinationChargePercent = destinationChargePercent
    }
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
    /// Connector types available at this charger
    public let connectorTypes: [EVConnectorType]
    public let recommendation: String

    public init(chargerStop: SmartStop, arrivalChargePercent: Double, recommendedChargePercent: Double,
                estimatedChargeTime: TimeInterval, estimatedCost: Double,
                connectorTypes: [EVConnectorType] = [.ccs], recommendation: String) {
        self.chargerStop = chargerStop
        self.arrivalChargePercent = arrivalChargePercent
        self.recommendedChargePercent = recommendedChargePercent
        self.estimatedChargeTime = estimatedChargeTime
        self.estimatedCost = estimatedCost
        self.connectorTypes = connectorTypes
        self.recommendation = recommendation
    }
}

public final class EvChargingPlannerService: EvChargingPlannerServiceProtocol, Sendable {
    public static let shared = EvChargingPlannerService()
    
    private init() {}
    
    /// Plans optimal EV charging stops using the selected vehicle's real specs.
    /// - Parameters:
    ///   - route: The route to analyze.
    ///   - chargers: A list of EV Charger POIs searched along the route.
    ///   - vehicle: The vehicle model (uses EvRangeConfig.selectedVehicle by default).
    ///   - startingChargePercent: Starting charge level (0-100, uses EvRangeConfig.defaultStartingCharge by default).
    ///   - thresholdPercent: Battery % that triggers a charging stop (default 15%).
    public func planChargingStops(
        for route: WizPathRoute,
        chargers: [SmartStop],
        vehicle: VehicleModel = EvRangeConfig.selectedVehicle,
        startingChargePercent: Double = EvRangeConfig.defaultStartingCharge,
        thresholdPercent: Double = EvRangeConfig.safetyBufferPercent
    ) async -> EvChargingPlan {
        guard route.travelMode == .car else {
            return EvChargingPlan(stops: [], totalChargingTime: 0, totalCost: 0, routeImpact: 0, destinationChargePercent: startingChargePercent)
        }
        
        let batteryCapacityKwh = vehicle.batteryCapacityKwh
        let maxChargeKw = vehicle.maxChargeSpeedKw
        let connectorTypes = vehicle.connectorTypes

        let rangeEstimate = await EvRangeService.shared.estimateRange(
            for: route,
            vehicle: vehicle,
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
                    
                    // Use vehicle's max charging speed for time estimation
                    // Real charging curves taper after 80%, but we use average 10-80% rate
                    let effectiveChargeKw = min(maxChargeKw, 150.0) // Conservative cap
                    let chargingTimeSeconds = effectiveChargeKw > 0 ? (energyToChargeKwh / effectiveChargeKw) * 3600.0 : 3600.0

                    // Cost: ~$0.42/kWh average (varies by region)
                    let stopCost = energyToChargeKwh * 0.42

                    let timeText = String(format: "%d min", Int(chargingTimeSeconds / 60.0))
                    let recommendation = WizPathKitL10n.formatted("ev_charge_recommendation", timeText, Int(arrivalCharge), Int(targetCharge))

                    // Filter chargers by compatible connector type
                    let compatibleConnectors = optimalCharger.connectorTypes.isEmpty
                        ? connectorTypes
                        : connectorTypes.filter { optimalCharger.connectorTypes.contains($0) }

                    plannedStops.append(ChargingStop(
                        chargerStop: optimalCharger,
                        arrivalChargePercent: arrivalCharge,
                        recommendedChargePercent: targetCharge,
                        estimatedChargeTime: chargingTimeSeconds,
                        estimatedCost: stopCost,
                        connectorTypes: compatibleConnectors.isEmpty ? connectorTypes : compatibleConnectors,
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
