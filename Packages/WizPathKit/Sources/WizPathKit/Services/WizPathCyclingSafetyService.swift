import Foundation
import CoreLocation

// MARK: - Cycling Safety Service

@MainActor
public final class WizPathCyclingSafetyService {
    public static let shared = WizPathCyclingSafetyService()

    public struct WindThresholds {
        /// Crosswind becomes hazardous for cyclists at this speed (km/h)
        public static let crosswindHazard: Double = 25
        /// Dangerous crosswind for all cyclists
        public static let crosswindDangerous: Double = 40
        /// Headwind that significantly increases effort
        public static let headwindSignificant: Double = 20
        /// Headwind that makes cycling impractical
        public static let headwindExtreme: Double = 45
    }

    public struct EffortLevel: Sendable {
        public let level: Int // 1-10
        public let title: String
        public let description: String
        public let extraTimePercent: Int // estimated time increase due to wind

        public init(level: Int, title: String, description: String, extraTimePercent: Int) {
            self.level = level
            self.title = title
            self.description = description
            self.extraTimePercent = extraTimePercent
        }

        public static func compute(windSpeed: Double, isHeadwind: Bool, temperature: Double, distance: CLLocationDistance) -> EffortLevel {
            let windFactor = isHeadwind ? windSpeed * 1.4 : windSpeed * 0.6 // headwind affects more
            let tempPenalty: Double
            if temperature > 30 { tempPenalty = 20 }
            else if temperature > 25 { tempPenalty = 10 }
            else if temperature < 5 { tempPenalty = 15 }
            else if temperature < 0 { tempPenalty = 25 }
            else { tempPenalty = 0 }

            let rawScore = (windFactor * 2.5 + tempPenalty) / 10.0
            let level = max(1, min(10, Int(rawScore.rounded())))

            let title: String
            let description: String
            let extraTime: Int

            if level <= 3 {
                title = WizPathKitL10n.text("wizpath_cycling_effort_low")
                description = WizPathKitL10n.text("wizpath_cycling_effort_desc_low")
                extraTime = 0
            } else if level <= 6 {
                title = WizPathKitL10n.text("wizpath_cycling_effort_moderate")
                description = WizPathKitL10n.text("wizpath_cycling_effort_desc_moderate")
                extraTime = Int(windFactor * 2)
            } else {
                title = WizPathKitL10n.text("wizpath_cycling_effort_high")
                description = WizPathKitL10n.text("wizpath_cycling_effort_desc_high")
                extraTime = Int(windFactor * 4)
            }

            return EffortLevel(level: level, title: title, description: description, extraTimePercent: extraTime)
        }
    }

    public enum CyclingSafety: Equatable, Sendable {
        case safe
        case caution(reason: String)
        case notRecommended(reason: String)

        public var isSafe: Bool { self == .safe }
        public var isRisky: Bool { self != .safe }
    }

    public struct CyclingSafetyAnalysis: Sendable {
        public let safety: CyclingSafety
        public let effortLevel: EffortLevel
        public let crosswindSegments: [CyclingWindSegment]
        public let headwindSegments: [CyclingWindSegment]
        public let overallWindSpeed: Double
        public let maxGustSpeed: Double

        public init(safety: CyclingSafety, effortLevel: EffortLevel, crosswindSegments: [CyclingWindSegment], headwindSegments: [CyclingWindSegment], overallWindSpeed: Double, maxGustSpeed: Double) {
            self.safety = safety
            self.effortLevel = effortLevel
            self.crosswindSegments = crosswindSegments
            self.headwindSegments = headwindSegments
            self.overallWindSpeed = overallWindSpeed
            self.maxGustSpeed = maxGustSpeed
        }

        public var hasCrosswindRisk: Bool { !crosswindSegments.isEmpty }
        public var hasSignificantHeadwind: Bool { !headwindSegments.isEmpty }
    }

    public struct CyclingWindSegment: Sendable, Identifiable {
        public let id = UUID()
        public let segmentIndex: Int
        public let windSpeed: Double
        public let isHeadwind: Bool
        public let eta: Date

        public init(segmentIndex: Int, windSpeed: Double, isHeadwind: Bool, eta: Date) {
            self.segmentIndex = segmentIndex
            self.windSpeed = windSpeed
            self.isHeadwind = isHeadwind
            self.eta = eta
        }
    }

    public init() {}

    /// Analyze a route for cycling safety considering wind, temperature, and precipitation
    public func analyzeCyclingSafety(route: WizPathRoute) -> CyclingSafetyAnalysis {
        guard route.travelMode == .cycling else {
            return CyclingSafetyAnalysis(
                safety: .safe,
                effortLevel: EffortLevel(level: 1, title: "-", description: "-", extraTimePercent: 0),
                crosswindSegments: [],
                headwindSegments: [],
                overallWindSpeed: 0,
                maxGustSpeed: 0
            )
        }

        var crosswindSegments: [CyclingWindSegment] = []
        var headwindSegments: [CyclingWindSegment] = []
        var totalWindSpeed: Double = 0
        var maxGust: Double = 0
        var windCount: Int = 0
        var hasPrecipitationHazard = false
        var maxTemperature: Double = 0

        for (index, segment) in route.segments.enumerated() {
            guard let weather = segment.weather else { continue }
            let wind = weather.windSpeed
            totalWindSpeed += wind
            windCount += 1
            maxGust = max(maxGust, wind)
            maxTemperature = max(maxTemperature, weather.temperature)

            // Crosswind detection (wind > threshold)
            if wind >= WindThresholds.crosswindHazard {
                crosswindSegments.append(CyclingWindSegment(
                    segmentIndex: index,
                    windSpeed: wind,
                    isHeadwind: false,
                    eta: segment.estimatedArrival
                ))
            }

            // Headwind detection (wind significantly slows cyclist)
            if wind >= WindThresholds.headwindSignificant {
                headwindSegments.append(CyclingWindSegment(
                    segmentIndex: index,
                    windSpeed: wind,
                    isHeadwind: true,
                    eta: segment.estimatedArrival
                ))
            }

            // Precipitation makes roads slippery
            if weather.precipitationChance > 0.3 && wind > 15 {
                hasPrecipitationHazard = true
            }
        }

        let avgWind = windCount > 0 ? totalWindSpeed / Double(windCount) : 0

        // Determine overall safety
        let isHeadwind = avgWind > 15 // Simplified: if avg wind is high, treat as headwind
        let effort = EffortLevel.compute(
            windSpeed: avgWind,
            isHeadwind: isHeadwind,
            temperature: maxTemperature,
            distance: route.totalDistance
        )

        let safety: CyclingSafety
        if maxGust >= WindThresholds.crosswindDangerous {
            safety = .notRecommended(reason: WizPathKitL10n.text("wizpath_cycling_not_recommended"))
        } else        if maxGust >= WindThresholds.crosswindHazard && hasPrecipitationHazard {
            safety = .notRecommended(reason: WizPathKitL10n.text("wizpath_cycling_crosswind_wet_reason"))
        } else if maxGust >= WindThresholds.crosswindHazard {
            safety = .caution(reason: WizPathKitL10n.text("wizpath_cycling_crosswind_caution_reason"))
        } else if hasPrecipitationHazard {
            safety = .caution(reason: WizPathKitL10n.text("wizpath_cycling_wet_roads_reason"))
        } else if effort.level >= 7 {
            safety = .caution(reason: WizPathKitL10n.text("wizpath_cycling_high_effort_reason"))
        } else {
            safety = .safe
        }

        return CyclingSafetyAnalysis(
            safety: safety,
            effortLevel: effort,
            crosswindSegments: crosswindSegments,
            headwindSegments: headwindSegments,
            overallWindSpeed: avgWind,
            maxGustSpeed: maxGust
        )
    }
}
