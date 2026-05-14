import Foundation
import OSLog

// MARK: - Departure Optimizer Service
/// Optimizes departure time based on weather, traffic, and climate conditions
/// Updated for v3.0: Extreme heat integration and Sentinel notification thresholds
@MainActor
final class DepartureOptimizerService {
    static let shared = DepartureOptimizerService()
    
    // MARK: - Multiplier Matrix (Gridlock & Climate)
    struct MultiplierMatrix {
        // Weather-based multipliers
        static let snowBlizzard: Double = 2.2        // Maximum priority
        static let heavyRain: Double = 1.6
        static let severeStorm: Double = 1.4
        static let moderateRain: Double = 1.2
        
        // Climate-based multipliers (NEW in v3.0)
        static let extremeHeat: Double = 1.25       // >40°C + Vehicle Stress
        static let highHeat: Double = 1.15          // 35-40°C
        static let moderateHeat: Double = 1.05      // 32-35°C
        
        // Traffic multipliers
        static let heavyTraffic: Double = 1.3
        static let moderateTraffic: Double = 1.15
        
        // Combined maximum (cap to prevent extreme ETAs)
        static let maximumMultiplier: Double = 3.0
    }
    
    // MARK: - Sentinel Thresholds
    struct SentinelThresholds {
        /// Minimum delay to trigger sentinel alert (30 minutes)
        static let minimumDelayMinutes: Double = 30
        
        /// Minimum percentage increase to trigger sentinel (40%)
        static let minimumPercentageIncrease: Double = 0.40
        
        /// Metropolitan gridlock threshold (2x normal time)
        static let gridlockMultiplier: Double = 2.0
    }
    
    // MARK: - Dependencies
    private let climateService: WizPathClimateService
    private let sentinelService: WizPathSentinelService
    
    private init(
        climateService: WizPathClimateService = .shared,
        sentinelService: WizPathSentinelService = .shared
    ) {
        self.climateService = climateService
        self.sentinelService = sentinelService
    }
    
    // MARK: - Departure Optimization
    
    /// Find optimal departure times with safe weather handling
    func findOptimalDepartures(
        route: WizPathRoute,
        mode: TravelMode,
        timeWindow: TimeInterval = 8 * 3600,
        interval: TimeInterval = 3600
    ) async -> DepartureOptimizationResult {
        let now = Date()
        var slots: [DepartureSlot] = []
        var hasWeatherDataError = false
        
        // Generate slots for the time window
        let slotCount = Int(timeWindow / interval)
        
        for i in 0...slotCount {
            let departureTime = now.addingTimeInterval(Double(i) * interval)
            
            // Calculate route for this departure
            let routeResult = await calculateRouteForDeparture(
                originalRoute: route,
                departureTime: departureTime,
                mode: mode
            )
            
            // Analyze climate impact
            let climateAnalysis = climateService.analyzeRouteClimate(
                routeResult.route,
                travelMode: mode
            )
            
            // Apply climate adjustments
            let adjustedRoute = climateService.applyClimateAdjustment(
                to: routeResult.route,
                analysis: climateAnalysis
            )
            
            // Calculate score (0-100)
            let score = calculateDepartureScore(
                adjustedRoute: adjustedRoute,
                climateAnalysis: climateAnalysis,
                mode: mode
            )
            
            // Get max temperature along route
            let maxTemp = climateAnalysis.maxTemperature
            
            let slot = DepartureSlot(
                time: departureTime,
                timeLabel: formatTime(departureTime),
                durationLabel: formatDuration(adjustedRoute.adjustedDuration),
                score: score,
                temperature: maxTemp,
                weatherCondition: getDominantConditionSafely(from: adjustedRoute.adjustedSegments),
                eta: adjustedRoute.adjustedDuration,
                climateAnalysis: climateAnalysis,
                adjustedRoute: adjustedRoute,
                hasWeatherDataError: hasWeatherDataError
            )
            
            slots.append(slot)
        }
        
        // Find best slot safely
        let bestSlot = slots.max(by: { $0.score < $1.score })
        
        return DepartureOptimizationResult(
            slots: slots,
            recommendedSlot: bestSlot,
            sentinelAlerts: [],
            climateSummary: generateClimateSummary(slots: slots),
            hasWeatherDataError: hasWeatherDataError,
            weatherUnavailableMessage: hasWeatherDataError 
                ? "Weather data unavailable for this route/time. Showing standard traffic estimates."
                : nil
        )
    }
    
    // MARK: - Route Calculation
    
    private func calculateRouteForDeparture(
        originalRoute: WizPathRoute,
        departureTime: Date,
        mode: TravelMode
    ) async -> RouteCalculationResult {
        // In production, this would recalculate the route with updated traffic data
        // For now, simulate time-based variations
        
        let hour = Calendar.current.component(.hour, from: departureTime)
        
        // Rush hour simulation
        var trafficMultiplier: Double = 1.0
        if (7...9).contains(hour) || (17...19).contains(hour) {
            trafficMultiplier = 1.3
        } else if (10...16).contains(hour) {
            trafficMultiplier = 1.1
        } else {
            trafficMultiplier = 1.0
        }
        
        let adjustedDuration = originalRoute.totalDuration * trafficMultiplier
        
        return RouteCalculationResult(
            route: originalRoute,
            baseDuration: originalRoute.totalDuration,
            adjustedDuration: adjustedDuration
        )
    }
    
    // MARK: - Scoring
    
    private func calculateDepartureScore(
        adjustedRoute: ClimateAdjustedRoute,
        climateAnalysis: ClimateAnalysis,
        mode: TravelMode
    ) -> Int {
        var score = 100
        
        // Climate penalties
        if climateAnalysis.isCriticalHeat {
            score -= 40 // Severe penalty for critical heat
        } else if climateAnalysis.isExtremeHeat {
            score -= 25 // Major penalty for extreme heat
        } else if climateAnalysis.maxTemperature >= 35 {
            score -= 10 // Minor penalty for high heat
        }
        
        // Time multiplier penalty
        let timePenalty = Int((adjustedRoute.multiplier - 1.0) * 50)
        score -= timePenalty
        
        // EV-specific penalties
        if mode == .car && climateAnalysis.maxTemperature >= 38 {
            score -= 15 // EV efficiency concern
        }
        
        // Pedestrian-specific penalties
        if mode == .walking && climateAnalysis.maxTemperature >= 36 {
            score -= 20 // Health risk
        }
        
        // Alert penalties
        let alertPenalty = climateAnalysis.alerts.count * 5
        score -= alertPenalty
        
        return max(0, min(100, score))
    }
    
    // MARK: - Sentinel Evaluation
    
    private func identifySentinelSlots(slots: [DepartureSlot]) -> [SentinelSlotAlert] {
        var alerts: [SentinelSlotAlert] = []
        
        guard let baselineSlot = slots.first else { return [] }
        let baselineDuration = baselineSlot.eta
        
        for slot in slots {
            let timeDifference = slot.eta - baselineDuration
            let percentageIncrease = timeDifference / baselineDuration
            
            // Check sentinel thresholds
            let meetsDelayThreshold = timeDifference >= (SentinelThresholds.minimumDelayMinutes * 60)
            let meetsPercentageThreshold = percentageIncrease >= SentinelThresholds.minimumPercentageIncrease
            
            if meetsDelayThreshold || meetsPercentageThreshold {
                // Determine cause
                let cause: SentinelCause
                if slot.temperature >= 40 {
                    cause = .extremeHeat(temperature: slot.temperature)
                } else if slot.temperature >= 35 {
                    cause = .highHeat(temperature: slot.temperature)
                } else if slot.eta > baselineDuration * 2 {
                    cause = .gridlock(multiplier: slot.eta / baselineDuration)
                } else {
                    cause = .generalWeather(condition: slot.weatherCondition)
                }
                
                let alert = SentinelSlotAlert(
                    slot: slot,
                    addedTime: timeDifference,
                    percentageIncrease: percentageIncrease,
                    cause: cause,
                    message: buildSentinelMessage(slot: slot, cause: cause, addedTime: timeDifference)
                )
                
                alerts.append(alert)
            }
        }
        
        return alerts
    }
    
    private func buildSentinelMessage(
        slot: DepartureSlot,
        cause: SentinelCause,
        addedTime: TimeInterval
    ) -> String {
        let minutes = Int(addedTime) / 60
        
        switch cause {
        case .extremeHeat(let temp):
            return L10n.formatted("sentinel_slot_heat", minutes, Int(temp))
        case .highHeat(let temp):
            return L10n.formatted("sentinel_slot_high_heat", minutes, Int(temp))
        case .gridlock(let multiplier):
            return L10n.formatted("sentinel_slot_gridlock", minutes, String(format: "%.1f", multiplier))
        case .generalWeather(let condition):
            return L10n.formatted("sentinel_slot_weather", minutes, condition.rawValue)
        }
    }
    
    // MARK: - Helpers
    
    private func getDominantConditionSafely(from segments: [WizPathSegment]) -> SegmentWeatherCondition {
        var conditionCounts: [SegmentWeatherCondition: Int] = [:]
        
        for segment in segments {
            if let weather = segment.weather {
                conditionCounts[weather.condition, default: 0] += 1
            }
        }
        
        return conditionCounts.max(by: { $0.value < $1.value })?.key ?? .clear
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    private func generateTerminalOutput(
        slot: Int,
        temperature: Double,
        addedTime: TimeInterval,
        multiplier: Double
    ) -> String {
        if temperature >= 40 {
            return "> CLIMATE_WARNING: Extreme Heat (\(Int(temperature))°C) detected at Destination. ETA adjusted."
        } else if temperature >= 36 {
            return "> CLIMATE_NOTICE: High heat (\(Int(temperature))°C) may affect travel comfort."
        } else if multiplier > 1.2 {
            let minutes = Int(addedTime) / 60
            return "> TRAFFIC_WARNING: Metropolitan gridlock detected. +\(minutes)min to ETA."
        }
        return "> ROUTE_OPTIMAL: Conditions favorable for departure."
    }
    
    private func generateClimateSummary(slots: [DepartureSlot]) -> ClimateSummary {
        let maxTemp = slots.map { $0.temperature }.max() ?? 0
        let avgTemp = slots.map { $0.temperature }.reduce(0, +) / Double(slots.count)
        let heatSlots = slots.filter { $0.temperature >= 36 }.count
        
        return ClimateSummary(
            maxTemperature: maxTemp,
            averageTemperature: avgTemp,
            extremeHeatSlots: slots.filter { $0.temperature >= 40 }.count,
            highHeatSlots: heatSlots,
            optimalSlots: slots.filter { $0.temperature < 32 && $0.score >= 70 }.count,
            recommendation: generateClimateRecommendation(maxTemp: maxTemp, heatSlots: heatSlots)
        )
    }
    
    private func generateClimateRecommendation(maxTemp: Double, heatSlots: Int) -> String {
        if maxTemp >= 42 {
            return L10n.text("climate_rec_critical_heat")
        } else if maxTemp >= 38 {
            return L10n.text("climate_rec_extreme_heat")
        } else if heatSlots > 3 {
            return L10n.text("climate_rec_multiple_heat")
        }
        return L10n.text("climate_rec_optimal")
    }
}

// MARK: - Supporting Types

struct RouteCalculationResult: Sendable {
    let route: WizPathRoute
    let baseDuration: TimeInterval
    let adjustedDuration: TimeInterval
}

struct DepartureOptimizationResult: Sendable {
    let slots: [DepartureSlot]
    let recommendedSlot: DepartureSlot?
    let sentinelAlerts: [SentinelSlotAlert]
    let climateSummary: ClimateSummary
    let hasWeatherDataError: Bool
    let weatherUnavailableMessage: String?
    
    var hasOptimalSlot: Bool {
        recommendedSlot?.score ?? 0 >= 70
    }
    
    var shouldShowWeatherWarning: Bool {
        hasWeatherDataError && weatherUnavailableMessage != nil
    }
}

struct SentinelSlotAlert: Sendable {
    let slot: DepartureSlot
    let addedTime: TimeInterval
    let percentageIncrease: Double
    let cause: SentinelCause
    let message: String
    
    var meetsSentinelThreshold: Bool {
        addedTime >= (30 * 60) || percentageIncrease >= 0.40
    }
}

enum SentinelCause: Sendable {
    case extremeHeat(temperature: Double)
    case highHeat(temperature: Double)
    case gridlock(multiplier: Double)
    case generalWeather(condition: SegmentWeatherCondition)
}

struct ClimateSummary: Sendable {
    let maxTemperature: Double
    let averageTemperature: Double
    let extremeHeatSlots: Int
    let highHeatSlots: Int
    let optimalSlots: Int
    let recommendation: String
    
    var hasHeatConcern: Bool {
        maxTemperature >= 36
    }
}

// MARK: - Updated Departure Slot
struct DepartureSlot: Identifiable, Sendable {
    let id = UUID()
    let time: Date
    let timeLabel: String
    let durationLabel: String
    let score: Int
    let temperature: Double
    let weatherCondition: SegmentWeatherCondition
    let eta: TimeInterval
    let climateAnalysis: ClimateAnalysis
    let adjustedRoute: ClimateAdjustedRoute
    let hasWeatherDataError: Bool
    
    var displayStatus: String {
        if hasWeatherDataError {
            return "Traffic estimate only"
        } else if temperature >= 40 {
            return "Extreme heat alert"
        } else if temperature >= 36 {
            return "Hot conditions"
        } else if score >= 80 {
            return "Optimal"
        } else if score >= 60 {
            return "Good"
        } else {
            return "Challenging"
        }
    }
}
