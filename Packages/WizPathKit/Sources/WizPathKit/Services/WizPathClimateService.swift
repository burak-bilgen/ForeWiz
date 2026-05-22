import Foundation
import CoreLocation
import OSLog

// MARK: - Climate Service
@MainActor
public final class WizPathClimateService {
    public static let shared = WizPathClimateService()

    public struct TemperatureThresholds {
        public static let evEfficiencyReduction: Double = 38.0
        public static let pedestrianHeatRisk: Double = 36.0
        public static let extremeHeat: Double = 40.0
        public static let criticalHeat: Double = 45.0
    }

    public struct ClimateMultipliers {
        public static let snowBlizzard: Double = 2.2
        public static let heavyRain: Double = 1.6
        public static let severeStorm: Double = 1.4
        public static let extremeHeat: Double = 1.25
        public static let highHeat: Double = 1.15
        public static let moderateHeat: Double = 1.05
    }

    public init() {}

    public func analyzeRouteClimate(_ route: WizPathRoute, travelMode: TravelMode) -> ClimateAnalysis {
        var alerts: [ClimateAlert] = []
        var multipliers: [ClimateMultiplier] = []
        var totalMultiplier: Double = 1.0
        var heatSegments: [RouteHeatSegment] = []
        var maxTemperature: Double = 0.0

        for (index, segment) in route.segments.enumerated() {
            guard let weather = segment.weather else { continue }
            let temp = weather.temperature
            maxTemperature = max(maxTemperature, temp)

            if temp >= TemperatureThresholds.pedestrianHeatRisk {
                let heatSegment = RouteHeatSegment(segmentIndex: index, temperature: temp, eta: segment.estimatedArrival, coordinate: segment.coordinate)
                heatSegments.append(heatSegment)

                if temp >= TemperatureThresholds.extremeHeat {
                    let multiplier = ClimateMultiplier(type: .extremeHeat, value: ClimateMultipliers.extremeHeat, segmentIndices: [index], description: WizPathKitL10n.formatted("climate_extreme_heat_desc", Int(temp)))
                    multipliers.append(multiplier)
                    totalMultiplier = max(totalMultiplier, ClimateMultipliers.extremeHeat)

                    if travelMode == .car {
                        alerts.append(ClimateAlert(type: .evBatteryEfficiency, severity: .high, title: WizPathKitL10n.text("climate_ev_battery_title"), message: WizPathKitL10n.formatted("climate_ev_battery_message", Int(temp)), eta: segment.estimatedArrival, recommendation: WizPathKitL10n.text("climate_ev_battery_recommendation")))
                    }
                    if travelMode == .walking || travelMode == .cycling {
                        alerts.append(ClimateAlert(type: .heatStrokeRisk, severity: .critical, title: WizPathKitL10n.text("climate_heat_stroke_title"), message: WizPathKitL10n.formatted("climate_heat_stroke_message", Int(temp)), eta: segment.estimatedArrival, recommendation: WizPathKitL10n.text("climate_heat_stroke_recommendation")))
                    }
                    alerts.append(ClimateAlert(type: .infrastructureStress, severity: .medium, title: WizPathKitL10n.text("climate_infrastructure_title"), message: WizPathKitL10n.formatted("climate_infrastructure_message", Int(temp)), eta: segment.estimatedArrival, recommendation: WizPathKitL10n.text("climate_infrastructure_recommendation")))
                } else if temp >= 35.0 {
                    multipliers.append(ClimateMultiplier(type: .highHeat, value: ClimateMultipliers.highHeat, segmentIndices: [index], description: WizPathKitL10n.formatted("climate_high_heat_desc", Int(temp))))
                    totalMultiplier = max(totalMultiplier, ClimateMultipliers.highHeat)
                }
            }

            switch weather.condition {
            case .snow where temp < 0:
                multipliers.append(ClimateMultiplier(type: .snowBlizzard, value: ClimateMultipliers.snowBlizzard, segmentIndices: [index], description: WizPathKitL10n.text("climate_snow_blizzard_desc")))
                totalMultiplier = max(totalMultiplier, ClimateMultipliers.snowBlizzard)
            case .heavyRain:
                multipliers.append(ClimateMultiplier(type: .heavyRain, value: ClimateMultipliers.heavyRain, segmentIndices: [index], description: WizPathKitL10n.text("climate_heavy_rain_desc")))
                totalMultiplier = max(totalMultiplier, ClimateMultipliers.heavyRain)
            case .thunderstorm:
                multipliers.append(ClimateMultiplier(type: .severeStorm, value: ClimateMultipliers.severeStorm, segmentIndices: [index], description: WizPathKitL10n.text("climate_severe_storm_desc")))
                totalMultiplier = max(totalMultiplier, ClimateMultipliers.severeStorm)
            default: break
            }
        }

        return ClimateAnalysis(maxTemperature: maxTemperature, totalMultiplier: totalMultiplier, multipliers: multipliers, alerts: alerts, heatSegments: heatSegments, requiresClimateAdjustment: totalMultiplier > 1.0 || !alerts.isEmpty)
    }

    public func applyClimateAdjustment(to route: WizPathRoute, analysis: ClimateAnalysis) -> ClimateAdjustedRoute {
        let adjustedDuration = route.totalDuration * analysis.totalMultiplier
        let addedTime = adjustedDuration - route.totalDuration
        var adjustedSegments = route.segments
        for i in adjustedSegments.indices {
            let segment = adjustedSegments[i]
            let segmentAdjustment = segment.travelTime * (analysis.totalMultiplier - 1.0)
            adjustedSegments[i] = WizPathSegment(id: segment.id, coordinate: segment.coordinate, estimatedArrival: segment.estimatedArrival.addingTimeInterval(segmentAdjustment), distanceFromStart: segment.distanceFromStart, travelTime: segment.travelTime, weather: segment.weather)
        }
        return ClimateAdjustedRoute(originalRoute: route, adjustedDuration: adjustedDuration, addedTime: addedTime, multiplier: analysis.totalMultiplier, analysis: analysis, adjustedSegments: adjustedSegments)
    }

    public func getHeatHealthRecommendations(temperature: Double, travelMode: TravelMode) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        if (travelMode == .walking || travelMode == .cycling) && temperature >= TemperatureThresholds.pedestrianHeatRisk {
            recommendations.append(HealthRecommendation(icon: "drop.fill", title: WizPathKitL10n.text("rec_hydration_title"), description: WizPathKitL10n.text("rec_hydration_desc")))
            recommendations.append(HealthRecommendation(icon: "tree.fill", title: WizPathKitL10n.text("rec_shade_title"), description: WizPathKitL10n.text("rec_shade_desc")))
            if temperature >= TemperatureThresholds.extremeHeat {
                recommendations.append(HealthRecommendation(icon: "clock.badge.exclamationmark", title: WizPathKitL10n.text("rec_timing_title"), description: WizPathKitL10n.text("rec_timing_desc")))
            }
        }
        return recommendations
    }

    public func getCyclingSafetyRecommendations(windSpeed: Double, temperature: Double, precipitationChance: Double) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        if windSpeed > 30 {
            recommendations.append(HealthRecommendation(
                icon: "wind",
                title: WizPathKitL10n.text("wizpath_cycling_crosswind_title"),
                description: WizPathKitL10n.formatted("wizpath_cycling_crosswind_message", "route", Int(windSpeed))
            ))
        }
        if temperature >= TemperatureThresholds.pedestrianHeatRisk {
            recommendations.append(HealthRecommendation(icon: "drop.fill", title: WizPathKitL10n.text("rec_hydration_title"), description: WizPathKitL10n.text("rec_hydration_desc")))
        }
        if precipitationChance > 0.3 {
            recommendations.append(HealthRecommendation(
                icon: "cloud.rain.fill",
                title: WizPathKitL10n.text("wizpath_cycling_wet_roads_title"),
                description: WizPathKitL10n.text("wizpath_cycling_wet_roads_desc")
            ))
        }
        return recommendations
    }

    public func getEVRecommendations(temperature: Double) -> [EVRecommendation] {
        var recommendations: [EVRecommendation] = []
        if temperature >= TemperatureThresholds.evEfficiencyReduction {
            recommendations.append(EVRecommendation(icon: "bolt.car.fill", title: WizPathKitL10n.text("rec_ev_precool_title"), description: WizPathKitL10n.text("rec_ev_precool_desc")))
            recommendations.append(EVRecommendation(icon: "gauge.with.dots.needle.67percent", title: WizPathKitL10n.text("rec_ev_speed_title"), description: WizPathKitL10n.text("rec_ev_speed_desc")))
            if temperature >= TemperatureThresholds.extremeHeat {
                recommendations.append(EVRecommendation(icon: "battery.75", title: WizPathKitL10n.text("rec_ev_buffer_title"), description: WizPathKitL10n.formatted("rec_ev_buffer_desc", Int(temperature))))
            }
        }
        return recommendations
    }
}

public struct ClimateAnalysis: Sendable {
    public let maxTemperature: Double
    public let totalMultiplier: Double
    public let multipliers: [ClimateMultiplier]
    public let alerts: [ClimateAlert]
    public let heatSegments: [RouteHeatSegment]
    public let requiresClimateAdjustment: Bool
    public var isExtremeHeat: Bool { maxTemperature >= WizPathClimateService.TemperatureThresholds.extremeHeat }
    public var isCriticalHeat: Bool { maxTemperature >= WizPathClimateService.TemperatureThresholds.criticalHeat }
    public var primaryAlert: ClimateAlert? { alerts.sorted(by: { $0.severity.rawValue > $1.severity.rawValue }).first }

    public init(maxTemperature: Double, totalMultiplier: Double, multipliers: [ClimateMultiplier], alerts: [ClimateAlert], heatSegments: [RouteHeatSegment], requiresClimateAdjustment: Bool) {
        self.maxTemperature = maxTemperature; self.totalMultiplier = totalMultiplier; self.multipliers = multipliers; self.alerts = alerts; self.heatSegments = heatSegments; self.requiresClimateAdjustment = requiresClimateAdjustment
    }
}

public struct RouteHeatSegment: Sendable { public let segmentIndex: Int; public let temperature: Double; public let eta: Date; public let coordinate: CLLocationCoordinate2D
    public init(segmentIndex: Int, temperature: Double, eta: Date, coordinate: CLLocationCoordinate2D) { self.segmentIndex = segmentIndex; self.temperature = temperature; self.eta = eta; self.coordinate = coordinate }
}
public struct ClimateMultiplier: Sendable { public let type: ClimateMultiplierType; public let value: Double; public let segmentIndices: [Int]; public let description: String
    public init(type: ClimateMultiplierType, value: Double, segmentIndices: [Int], description: String) { self.type = type; self.value = value; self.segmentIndices = segmentIndices; self.description = description }
}
public enum ClimateMultiplierType: String, Sendable {
    case snowBlizzard, heavyRain, severeStorm, extremeHeat, highHeat, moderateHeat, gridlock
    public var displayName: String {
        switch self {
        case .snowBlizzard: return WizPathKitL10n.text("multiplier_snow")
        case .heavyRain: return WizPathKitL10n.text("multiplier_rain")
        case .severeStorm: return WizPathKitL10n.text("multiplier_storm")
        case .extremeHeat: return WizPathKitL10n.text("multiplier_extreme_heat")
        case .highHeat: return WizPathKitL10n.text("multiplier_high_heat")
        case .moderateHeat: return WizPathKitL10n.text("multiplier_moderate_heat")
        case .gridlock: return WizPathKitL10n.text("multiplier_gridlock")
        }
    }
}
public struct ClimateAlert: Sendable { public let type: ClimateAlertType; public let severity: ClimateAlertSeverity; public let title: String; public let message: String; public let eta: Date; public let recommendation: String
    public init(type: ClimateAlertType, severity: ClimateAlertSeverity, title: String, message: String, eta: Date, recommendation: String) { self.type = type; self.severity = severity; self.title = title; self.message = message; self.eta = eta; self.recommendation = recommendation }
}
public enum ClimateAlertType: String, Sendable { case evBatteryEfficiency, heatStrokeRisk, infrastructureStress, roadClosureRisk }
public enum ClimateAlertSeverity: String, Sendable { case low, medium, high, critical }
public struct ClimateAdjustedRoute: Sendable {
    public let originalRoute: WizPathRoute; public let adjustedDuration: TimeInterval; public let addedTime: TimeInterval; public let multiplier: Double; public let analysis: ClimateAnalysis; public let adjustedSegments: [WizPathSegment]
    public init(originalRoute: WizPathRoute, adjustedDuration: TimeInterval, addedTime: TimeInterval, multiplier: Double, analysis: ClimateAnalysis, adjustedSegments: [WizPathSegment]) { self.originalRoute = originalRoute; self.adjustedDuration = adjustedDuration; self.addedTime = addedTime; self.multiplier = multiplier; self.analysis = analysis; self.adjustedSegments = adjustedSegments }
    public var formattedAddedTime: String {
        let minutes = Int(addedTime) / 60
        if minutes < 60 { return WizPathKitL10n.formatted("climate_added_minutes", minutes) }
        else { let h = minutes / 60; let m = minutes % 60; return WizPathKitL10n.formatted("climate_added_hours_minutes", h, m) }
    }
}
public struct HealthRecommendation: Sendable { public let icon: String; public let title: String; public let description: String
    public init(icon: String, title: String, description: String) { self.icon = icon; self.title = title; self.description = description }
}
public struct EVRecommendation: Sendable { public let icon: String; public let title: String; public let description: String
    public init(icon: String, title: String, description: String) { self.icon = icon; self.title = title; self.description = description }
}
