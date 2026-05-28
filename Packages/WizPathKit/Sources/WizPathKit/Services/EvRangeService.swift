import Foundation
import CoreLocation

public struct EvRangeEstimate: Sendable {
    public let baseRangeKm: Double        // EPA-rated range
    public let adjustedRangeKm: Double    // Weather-adjusted
    public let consumptionWhPerKm: Double // Weather-adjusted average consumption
    public let segments: [EvSegmentRange]
    public let recommendedChargeLevel: Double  // % needed to complete route safely
    public let estimatedChargeStops: Int
}

public struct EvSegmentRange: Sendable {
    public let segmentIndex: Int
    public let rangeConsumption: Double   // km of range consumed on this segment
    public let energyUsedKwh: Double      // kWh consumed on this segment
    public let factors: [EvRangeFactor]
}

public enum EvRangeFactor: Sendable, Equatable {
    case temperature(degrees: Double, penaltyPercent: Double)
    case wind(speedKph: Double, penaltyPercent: Double)
    case precipitation(chance: Double, penaltyPercent: Double)
    case generalHighSpeed(penaltyPercent: Double)
    case elevation(gradientPercent: Double, penaltyPercent: Double)
}

public final class EvRangeService: Sendable {
    public static let shared = EvRangeService()
    
    private init() {}
    
    /// Predicts range and consumption for an EV traveling along a WizPathRoute.
    /// - Parameters:
    ///   - route: The route to analyze.
    ///   - baseRangeKm: The vehicle's EPA-rated base range in km (default is 400km).
    ///   - batteryCapacityKwh: The vehicle's battery capacity in kWh (default is 75 kWh).
    ///   - startingChargePercent: The starting battery level (0.0 to 100.0, default is 80.0).
    public func estimateRange(
        for route: WizPathRoute,
        baseRangeKm: Double = 400.0,
        batteryCapacityKwh: Double = 75.0,
        startingChargePercent: Double = 80.0
    ) async -> EvRangeEstimate {
        let baseConsumptionWhPerKm = (batteryCapacityKwh * 1000.0) / baseRangeKm
        
        let elevationProfile = try? await ElevationService.shared.fetchElevationProfile(for: route)
        
        var segmentEstimates: [EvSegmentRange] = []
        var totalEnergyUsedKwh: Double = 0.0
        var totalDistanceKm: Double = 0.0
        
        for (index, segment) in route.segments.enumerated() {
            let segmentDistanceKm = (route.totalDistance / Double(route.segments.count)) / 1000.0
            totalDistanceKm += segmentDistanceKm
            
            var tempPenalty = 0.0
            var windPenalty = 0.0
            var precipPenalty = 0.0
            var speedPenalty = 0.0
            var factors: [EvRangeFactor] = []
            
            if let weather = segment.weather {
                let temp = weather.temperature
                // Cold weather battery penalty (under 15°C, battery loses efficiency)
                if temp < 0 {
                    tempPenalty = 0.20 + (abs(temp) * 0.01) // 20% + 1% per degree below 0
                } else if temp < 15 {
                    tempPenalty = (15.0 - temp) * 0.013 // ~1.3% per degree below 15
                }
                // Hot weather AC load penalty (above 30°C)
                else if temp > 35 {
                    tempPenalty = 0.15 + ((temp - 35.0) * 0.01)
                } else if temp > 28 {
                    tempPenalty = (temp - 28.0) * 0.015
                }
                
                if tempPenalty > 0 {
                    factors.append(.temperature(degrees: temp, penaltyPercent: tempPenalty * 100.0))
                }
                
                // Wind resistance (aerodynamic drag increases with speed squared)
                let wind = weather.windSpeed
                if wind > 15.0 {
                    windPenalty = (wind - 15.0) * 0.003
                    factors.append(.wind(speedKph: wind, penaltyPercent: windPenalty * 100.0))
                }
                
                // Precipitation rolling resistance penalty (wet/snowy roads increase friction)
                let precip = weather.precipitationChance
                if precip > 0.2 {
                    precipPenalty = precip * 0.05 // up to 5% penalty
                    factors.append(.precipitation(chance: precip, penaltyPercent: precipPenalty * 100.0))
                }
            }
            
            // Road type / High speed penalty (highway speeds are less efficient for EVs)
            if route.travelMode == .car {
                let speedKph = (segmentDistanceKm / (segment.travelTime / 3600.0))
                if speedKph > 100.0 {
                    speedPenalty = (speedKph - 100.0) * 0.006 // 0.6% penalty per km/h above 100
                    factors.append(.generalHighSpeed(penaltyPercent: speedPenalty * 100.0))
                }
            }
            
            // Elevation / Gradient penalty and regenerative braking recovery calculation
            var gradientMultiplier = 1.0
            if let profile = elevationProfile, profile.points.indices.contains(index) {
                let gradient = profile.points[index].gradientPercent
                if gradient > 5.0 {
                    gradientMultiplier = 2.5
                    factors.append(.elevation(gradientPercent: gradient, penaltyPercent: 150.0))
                } else if gradient >= 2.0 {
                    gradientMultiplier = 1.5
                    factors.append(.elevation(gradientPercent: gradient, penaltyPercent: 50.0))
                } else if gradient < -2.0 {
                    gradientMultiplier = 0.4 // Regenerative braking recovers 60% of potential energy
                    factors.append(.elevation(gradientPercent: gradient, penaltyPercent: -60.0))
                }
            }
            
            let combinedPenaltyMultiplier = (1.0 + tempPenalty + windPenalty + precipPenalty + speedPenalty) * gradientMultiplier
            let segmentEnergyWh = baseConsumptionWhPerKm * segmentDistanceKm * combinedPenaltyMultiplier
            let energyUsedKwh = segmentEnergyWh / 1000.0
            totalEnergyUsedKwh += energyUsedKwh
            
            let rangeConsumptionKm = segmentDistanceKm * combinedPenaltyMultiplier
            
            segmentEstimates.append(EvSegmentRange(
                segmentIndex: index,
                rangeConsumption: rangeConsumptionKm,
                energyUsedKwh: energyUsedKwh,
                factors: factors
            ))
        }
        
        let avgConsumptionWhPerKm = (totalEnergyUsedKwh * 1000.0) / max(0.1, totalDistanceKm)
        let adjustedRangeKm = (batteryCapacityKwh * 1000.0) / max(1.0, avgConsumptionWhPerKm)
        
        // Recommended charge calculation
        let safetyBufferKwh = batteryCapacityKwh * 0.15 // 15% buffer
        let energyNeededWithBufferKwh = totalEnergyUsedKwh + safetyBufferKwh
        let recommendedChargePercent = min(100.0, (energyNeededWithBufferKwh / batteryCapacityKwh) * 100.0)
        
        // Estimate charging stops needed based on starting charge
        let initialEnergyKwh = batteryCapacityKwh * (startingChargePercent / 100.0)
        var stopsCount = 0
        if initialEnergyKwh < energyNeededWithBufferKwh {
            let deficitKwh = energyNeededWithBufferKwh - initialEnergyKwh
            // Assume average charge session adds ~40kWh (approx. 20% to 80% on 75kWh battery)
            let divisor = batteryCapacityKwh * 0.60
            let rawCount = divisor > 0 ? deficitKwh / divisor : 0
            stopsCount = rawCount.isFinite ? Int(ceil(rawCount)) : 0
        }
        
        return EvRangeEstimate(
            baseRangeKm: baseRangeKm,
            adjustedRangeKm: adjustedRangeKm,
            consumptionWhPerKm: avgConsumptionWhPerKm,
            segments: segmentEstimates,
            recommendedChargeLevel: recommendedChargePercent,
            estimatedChargeStops: stopsCount
        )
    }
}
