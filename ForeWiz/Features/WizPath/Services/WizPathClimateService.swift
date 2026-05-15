import Foundation
import CoreLocation
import OSLog

// MARK: - Climate Service
/// Extreme heat and climate-aware route analytics
/// Handles EV battery alerts, health warnings, and infrastructure stress
@MainActor
final class WizPathClimateService {
    static let shared = WizPathClimateService()
    
    // MARK: - Temperature Thresholds
    struct TemperatureThresholds {
        /// EV battery efficiency reduction threshold (38°C / 100°F)
        static let evEfficiencyReduction: Double = 38.0
        
        /// Heat stroke risk threshold for pedestrians (36°C / 97°F)
        static let pedestrianHeatRisk: Double = 36.0
        
        /// Extreme heat infrastructure stress (40°C / 104°F)
        static let extremeHeat: Double = 40.0
        
        /// Critical heat danger level (45°C / 113°F)
        static let criticalHeat: Double = 45.0
    }
    
    // MARK: - Climate Multipliers
    struct ClimateMultipliers {
        /// Snow/Blizzard: Maximum priority
        static let snowBlizzard: Double = 2.2
        
        /// Heavy rain multiplier
        static let heavyRain: Double = 1.6
        
        /// Severe storm multiplier
        static let severeStorm: Double = 1.4
        
        /// Extreme heat (>40°C) with vehicle stress
        static let extremeHeat: Double = 1.25
        
        /// High heat (35-40°C) minor impact
        static let highHeat: Double = 1.15
        
        /// Moderate heat (32-35°C)
        static let moderateHeat: Double = 1.05
    }
    
    // MARK: - Climate Analysis
    
    /// Analyze route for climate-related risks and adjustments
    func analyzeRouteClimate(
        _ route: WizPathRoute,
        travelMode: TravelMode
    ) -> ClimateAnalysis {
        var alerts: [ClimateAlert] = []
        var multipliers: [ClimateMultiplier] = []
        var totalMultiplier: Double = 1.0
        var heatSegments: [RouteHeatSegment] = []
        var maxTemperature: Double = 0.0
        
        // Analyze each segment
        for (index, segment) in route.segments.enumerated() {
            guard let weather = segment.weather else { continue }
            
            let temp = weather.temperature
            maxTemperature = max(maxTemperature, temp)
            
            // Check for heat conditions
            if temp >= TemperatureThresholds.pedestrianHeatRisk {
                let heatSegment = RouteHeatSegment(
                    segmentIndex: index,
                    temperature: temp,
                    eta: segment.estimatedArrival,
                    coordinate: segment.coordinate
                )
                heatSegments.append(heatSegment)
                
                // Determine heat severity
                if temp >= TemperatureThresholds.extremeHeat {
                    // Extreme heat - apply multiplier
                    let multiplier = ClimateMultiplier(
                        type: .extremeHeat,
                        value: ClimateMultipliers.extremeHeat,
                        segmentIndices: [index],
                        description: L10n.formatted("climate_extreme_heat_desc", Int(temp))
                    )
                    multipliers.append(multiplier)
                    totalMultiplier = max(totalMultiplier, ClimateMultipliers.extremeHeat)
                    
                    // EV Battery Alert
                    if travelMode == .car {
                        let alert = ClimateAlert(
                            type: .evBatteryEfficiency,
                            severity: .high,
                            title: L10n.text("climate_ev_battery_title"),
                            message: L10n.formatted("climate_ev_battery_message", Int(temp)),
                            eta: segment.estimatedArrival,
                            recommendation: L10n.text("climate_ev_battery_recommendation")
                        )
                        alerts.append(alert)
                    }
                    
                    // Pedestrian Health Alert
                    if travelMode == .walking {
                        let alert = ClimateAlert(
                            type: .heatStrokeRisk,
                            severity: .critical,
                            title: L10n.text("climate_heat_stroke_title"),
                            message: L10n.formatted("climate_heat_stroke_message", Int(temp)),
                            eta: segment.estimatedArrival,
                            recommendation: L10n.text("climate_heat_stroke_recommendation")
                        )
                        alerts.append(alert)
                    }
                    
                    // Infrastructure stress warning
                    let stressAlert = ClimateAlert(
                        type: .infrastructureStress,
                        severity: .medium,
                        title: L10n.text("climate_infrastructure_title"),
                        message: L10n.formatted("climate_infrastructure_message", Int(temp)),
                        eta: segment.estimatedArrival,
                        recommendation: L10n.text("climate_infrastructure_recommendation")
                    )
                    alerts.append(stressAlert)
                    
                } else if temp >= 35.0 {
                    // High heat (35-40°C)
                    let multiplier = ClimateMultiplier(
                        type: .highHeat,
                        value: ClimateMultipliers.highHeat,
                        segmentIndices: [index],
                        description: L10n.formatted("climate_high_heat_desc", Int(temp))
                    )
                    multipliers.append(multiplier)
                    totalMultiplier = max(totalMultiplier, ClimateMultipliers.highHeat)
                }
            }
            
            // Check other weather conditions for multipliers
            switch weather.condition {
            case .snow where temp < 0:
                // Blizzard conditions
                let multiplier = ClimateMultiplier(
                    type: .snowBlizzard,
                    value: ClimateMultipliers.snowBlizzard,
                    segmentIndices: [index],
                    description: L10n.text("climate_snow_blizzard_desc")
                )
                multipliers.append(multiplier)
                totalMultiplier = max(totalMultiplier, ClimateMultipliers.snowBlizzard)
                
            case .heavyRain:
                let multiplier = ClimateMultiplier(
                    type: .heavyRain,
                    value: ClimateMultipliers.heavyRain,
                    segmentIndices: [index],
                    description: L10n.text("climate_heavy_rain_desc")
                )
                multipliers.append(multiplier)
                totalMultiplier = max(totalMultiplier, ClimateMultipliers.heavyRain)
                
            case .thunderstorm:
                let multiplier = ClimateMultiplier(
                    type: .severeStorm,
                    value: ClimateMultipliers.severeStorm,
                    segmentIndices: [index],
                    description: L10n.text("climate_severe_storm_desc")
                )
                multipliers.append(multiplier)
                totalMultiplier = max(totalMultiplier, ClimateMultipliers.severeStorm)
                
            default:
                break
            }
        }
        
        return ClimateAnalysis(
            maxTemperature: maxTemperature,
            totalMultiplier: totalMultiplier,
            multipliers: multipliers,
            alerts: alerts,
            heatSegments: heatSegments,
            requiresClimateAdjustment: totalMultiplier > 1.0 || !alerts.isEmpty
        )
    }
    
    // MARK: - ETA Adjustment
    
    /// Apply climate multiplier to route ETA
    func applyClimateAdjustment(
        to route: WizPathRoute,
        analysis: ClimateAnalysis
    ) -> ClimateAdjustedRoute {
        let adjustedDuration = route.totalDuration * analysis.totalMultiplier
        let addedTime = adjustedDuration - route.totalDuration
        
        // Adjust segment ETAs
        var adjustedSegments = route.segments
        for i in adjustedSegments.indices {
            let segment = adjustedSegments[i]
            let segmentAdjustment = segment.travelTime * (analysis.totalMultiplier - 1.0)
            adjustedSegments[i] = WizPathSegment(
                id: segment.id,
                coordinate: segment.coordinate,
                estimatedArrival: segment.estimatedArrival.addingTimeInterval(segmentAdjustment),
                distanceFromStart: segment.distanceFromStart,
                travelTime: segment.travelTime,
                weather: segment.weather
            )
        }
        
        return ClimateAdjustedRoute(
            originalRoute: route,
            adjustedDuration: adjustedDuration,
            addedTime: addedTime,
            multiplier: analysis.totalMultiplier,
            analysis: analysis,
            adjustedSegments: adjustedSegments
        )
    }
    
    // MARK: - Health Recommendations
    
    /// Get health recommendations for extreme heat
    func getHeatHealthRecommendations(
        temperature: Double,
        travelMode: TravelMode
    ) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        if travelMode == .walking && temperature >= TemperatureThresholds.pedestrianHeatRisk {
            recommendations.append(HealthRecommendation(
                icon: "drop.fill",
                title: L10n.text("rec_hydration_title"),
                description: L10n.text("rec_hydration_desc")
            ))
            
            recommendations.append(HealthRecommendation(
                icon: "tree.fill",
                title: L10n.text("rec_shade_title"),
                description: L10n.text("rec_shade_desc")
            ))
            
            if temperature >= TemperatureThresholds.extremeHeat {
                recommendations.append(HealthRecommendation(
                    icon: "clock.badge.exclamationmark",
                    title: L10n.text("rec_timing_title"),
                    description: L10n.text("rec_timing_desc")
                ))
            }
        }
        
        return recommendations
    }
    
    // MARK: - EV Recommendations
    
    /// Get EV-specific recommendations for extreme heat
    func getEVRecommendations(temperature: Double) -> [EVRecommendation] {
        var recommendations: [EVRecommendation] = []
        
        if temperature >= TemperatureThresholds.evEfficiencyReduction {
            recommendations.append(EVRecommendation(
                icon: "bolt.car.fill",
                title: L10n.text("rec_ev_precool_title"),
                description: L10n.text("rec_ev_precool_desc")
            ))
            
            recommendations.append(EVRecommendation(
                icon: "gauge.with.dots.needle.67percent",
                title: L10n.text("rec_ev_speed_title"),
                description: L10n.text("rec_ev_speed_desc")
            ))
            
            if temperature >= TemperatureThresholds.extremeHeat {
                recommendations.append(EVRecommendation(
                    icon: "battery.75",
                    title: L10n.text("rec_ev_buffer_title"),
                    description: L10n.formatted("rec_ev_buffer_desc", Int(temperature))
                ))
            }
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

struct ClimateAnalysis: Sendable {
    let maxTemperature: Double
    let totalMultiplier: Double
    let multipliers: [ClimateMultiplier]
    let alerts: [ClimateAlert]
    let heatSegments: [RouteHeatSegment]
    let requiresClimateAdjustment: Bool
    
    var isExtremeHeat: Bool {
        maxTemperature >= WizPathClimateService.TemperatureThresholds.extremeHeat
    }
    
    var isCriticalHeat: Bool {
        maxTemperature >= WizPathClimateService.TemperatureThresholds.criticalHeat
    }
}

struct RouteHeatSegment: Sendable {
    let segmentIndex: Int
    let temperature: Double
    let eta: Date
    let coordinate: CLLocationCoordinate2D
}

struct ClimateMultiplier: Sendable {
    let type: ClimateMultiplierType
    let value: Double
    let segmentIndices: [Int]
    let description: String
}

enum ClimateMultiplierType: String, Sendable {
    case snowBlizzard
    case heavyRain
    case severeStorm
    case extremeHeat
    case highHeat
    case moderateHeat
    case gridlock
    
    var displayName: String {
        switch self {
        case .snowBlizzard: return L10n.text("multiplier_snow")
        case .heavyRain: return L10n.text("multiplier_rain")
        case .severeStorm: return L10n.text("multiplier_storm")
        case .extremeHeat: return L10n.text("multiplier_extreme_heat")
        case .highHeat: return L10n.text("multiplier_high_heat")
        case .moderateHeat: return L10n.text("multiplier_moderate_heat")
        case .gridlock: return L10n.text("multiplier_gridlock")
        }
    }
}

struct ClimateAlert: Sendable {
    let type: ClimateAlertType
    let severity: ClimateAlertSeverity
    let title: String
    let message: String
    let eta: Date
    let recommendation: String
}

enum ClimateAlertType: String, Sendable {
    case evBatteryEfficiency
    case heatStrokeRisk
    case infrastructureStress
    case roadClosureRisk
}

enum ClimateAlertSeverity: String, Sendable {
    case low, medium, high, critical
}

struct ClimateAdjustedRoute: Sendable {
    let originalRoute: WizPathRoute
    let adjustedDuration: TimeInterval
    let addedTime: TimeInterval
    let multiplier: Double
    let analysis: ClimateAnalysis
    let adjustedSegments: [WizPathSegment]
    
    var formattedAddedTime: String {
        let minutes = Int(addedTime) / 60
        if minutes < 60 {
            return L10n.formatted("climate_added_minutes", minutes)
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return L10n.formatted("climate_added_hours_minutes", hours, mins)
        }
    }
    
    var terminalOutput: String {
        if analysis.isExtremeHeat {
            return "> CLIMATE_WARNING: Extreme Heat (\(Int(analysis.maxTemperature))°C) detected. ETA adjusted \(formattedAddedTime)."
        } else if multiplier > 1.0 {
            return "> CLIMATE_ADJUSTMENT: Weather conditions added \(formattedAddedTime) to ETA."
        }
        return "> ROUTE_CLEAR: No climate adjustments needed."
    }
}

struct HealthRecommendation: Sendable {
    let icon: String
    let title: String
    let description: String
}

struct EVRecommendation: Sendable {
    let icon: String
    let title: String
    let description: String
}
