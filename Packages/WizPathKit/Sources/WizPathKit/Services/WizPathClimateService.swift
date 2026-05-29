import Foundation
import CoreLocation
import OSLog

// MARK: - Climate Service
@MainActor
public final class WizPathClimateService {
    public static let shared = WizPathClimateService()

    /// 🌡️ Temperature thresholds with NOAA/NWS-aligned values
    public struct TemperatureThresholds {
        // EV battery efficiency
        public static let evEfficiencyReduction: Double = 38.0
        // Heat risk thresholds (NWS heat index categories)
        public static let pedestrianHeatRisk: Double = 36.0  // ~97°F — caution
        public static let extremeHeat: Double = 40.0          // ~104°F — danger
        public static let criticalHeat: Double = 45.0         // ~113°F — extreme danger
        // Wind chill thresholds (NWS wind chill chart)
        public static let windChillCaution: Double = -10.0    // °C — frostbite in 30 min
        public static let windChillDanger: Double = -20.0     // °C — frostbite in 10 min
        public static let windChillExtreme: Double = -30.0    // °C — frostbite in 5 min
        // Heat index thresholds
        public static let heatIndexCaution: Double = 27.0     // ~80°F
        public static let heatIndexExtreme: Double = 33.0     // ~91°F
        public static let heatIndexDanger: Double = 41.0      // ~105°F
    }

    public struct ClimateMultipliers {
        public static let snowBlizzard: Double = 2.2
        public static let heavyRain: Double = 1.6
        public static let severeStorm: Double = 1.4
        public static let extremeHeat: Double = 1.25
        public static let highHeat: Double = 1.15
        public static let moderateHeat: Double = 1.05
        // Cycling-specific wind resistance multiplier
        public static let highWindCycling: Double = 1.35
        // Wind chill adds to effective time penalty for exposed modes
        public static let windChillPenalty: Double = 1.15
    }

    public init() {}

    // MARK: - Wind Chill & Heat Index (NOAA/NWS Formulas)

    /// Calculates wind chill temperature in °C using the NWS/JMA formula.
    /// Valid for temperatures ≤ 10°C and wind speeds ≥ 4.8 km/h.
    /// Returns the wind chill temperature. If conditions are outside valid range,
    /// returns the actual temperature.
    public static func windChillCelsius(temperature: Double, windSpeedKph: Double) -> Double {
        // Wind chill is only defined for temps ≤ 10°C and wind ≥ 4.8 km/h
        guard temperature <= 10.0, windSpeedKph >= 4.8 else { return temperature }
        // Wind speed in mph for the NWS formula
        let windMph = windSpeedKph * 0.621371
        // NWS wind chill formula: 35.74 + 0.6215*T - 35.75*(V^0.16) + 0.4275*T*(V^0.16)
        // where T is °F, V is mph
        let tempF = temperature * 9.0 / 5.0 + 32.0
        let vPow = pow(windMph, 0.16)
        let windChillF = 35.74 + 0.6215 * tempF - 35.75 * vPow + 0.4275 * tempF * vPow
        // Convert back to °C
        return (windChillF - 32.0) * 5.0 / 9.0
    }

    /// Calculates heat index in °C using the NWS Rothfusz regression.
    /// Valid for temperatures ≥ 27°C and humidity (approximated from conditions).
    /// Returns the heat index temperature. If conditions are outside valid range,
    /// returns the actual temperature.
    public static func heatIndexCelsius(temperature: Double, humidityPercent: Double) -> Double {
        // Heat index is only defined for temps ≥ 27°C (80°F)
        guard temperature >= 27.0 else { return temperature }
        // Use a default humidity estimate if humidity is 0 (no data)
        let h = max(40, min(100, humidityPercent))
        let tempF = temperature * 9.0 / 5.0 + 32.0
        // Rothfusz regression
        let hiF = -42.379
            + 2.04901523 * tempF
            + 10.14333127 * Double(h)
            - 0.22475541 * tempF * Double(h)
            - 6.83783e-3 * tempF * tempF
            - 5.481717e-2 * Double(h) * Double(h)
            + 1.22874e-3 * tempF * tempF * Double(h)
            + 8.5282e-4 * tempF * Double(h) * Double(h)
            - 1.99e-6 * tempF * tempF * Double(h) * Double(h)
        // Adjust for low humidity (if adjustment is needed)
        let adjustedHI: Double
        if h < 13, temperature > 27.0, temperature < 43.0 {
            adjustedHI = hiF - ((13.0 - h) / 4.0) * sqrt((17.0 - abs(tempF - 95.0)) / 17.0)
        } else {
            adjustedHI = hiF
        }
        return (adjustedHI - 32.0) * 5.0 / 9.0
    }

    /// Estimates relative humidity from weather conditions and temperature
    public static func estimatedHumidity(temperature: Double, condition: SegmentWeatherCondition, precipitationChance: Double) -> Double {
        switch condition {
        case .thunderstorm, .heavyRain:
            return 85 + precipitationChance * 10
        case .rain, .snow, .sleet:
            return 70 + precipitationChance * 20
        case .fog:
            return 90 + precipitationChance * 5
        case .cloudy:
            return 60 + precipitationChance * 15
        case .partlyCloudy:
            return 45 + precipitationChance * 15
        case .clear:
            return max(30, 40 - (temperature - 15) * 1.5)
        case .windy:
            return 50
        case .unknown:
            return 55
        }
    }

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
