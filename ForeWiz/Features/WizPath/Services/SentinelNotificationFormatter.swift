import Foundation
import UserNotifications

// MARK: - Sentinel Notification Formatter
/// Formats high-value sentinel notifications with weather-specific content
/// Implements the v3.0 noise reduction protocol (>30min or >40% threshold)
@MainActor
final class SentinelNotificationFormatter {
    static let shared = SentinelNotificationFormatter()
    
    private init() {}
    
    // MARK: - Main Formatting Methods
    
    /// Format a sentinel notification with weather-specific details
    func formatNotification(
        for alert: SentinelAlert,
        context: NotificationContext
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Set notification properties based on severity
        configurePriority(content: content, severity: alert.severity)
        
        // Build title with weather type
        content.title = buildTitle(for: alert, context: context)
        
        // Build body with specific details
        content.body = buildBody(for: alert, context: context)
        
        // Add category for actions
        content.categoryIdentifier = "SENTINEL_ALERT"
        
        // Add user info for deep linking
        content.userInfo = buildUserInfo(for: alert, context: context)
        
        return content
    }
    
    // MARK: - Title Building
    
    private func buildTitle(for alert: SentinelAlert, context: NotificationContext) -> String {
        let addedTime = formatTimeDifference(alert.timeDifference)
        
        switch context.weatherType {
        case .extremeHeat(let temp):
            return "🌡️ EXTREME HEAT: +\(addedTime) Added"
            
        case .heavySnow:
            return "❄️ HEAVY SNOW: +\(addedTime) to Journey"
            
        case .blizzard:
            return "🌨️ BLIZZARD WARNING: +\(addedTime) Critical Delay"
            
        case .severeStorm:
            return "⛈️ SEVERE STORM: +\(addedTime) Delay Expected"
            
        case .gridlock:
            return "🚗 METROPOLITAN GRIDLOCK: +\(addedTime)"
            
        case .flooding:
            return "🌊 FLOODING ALERT: +\(addedTime) Route Impact"
            
        case .highWinds:
            return "💨 HIGH WINDS: +\(addedTime) Safety Delay"
            
        default:
            return "⚠️ TRAVEL ALERT: +\(addedTime) Delay Detected"
        }
    }
    
    // MARK: - Body Building
    
    private func buildBody(for alert: SentinelAlert, context: NotificationContext) -> String {
        var components: [String] = []
        
        // Original vs Updated times
        let originalTime = formatDuration(alert.originalDuration)
        let newTime = formatDuration(alert.updatedDuration)
        components.append("ETA changed from \(originalTime) to \(newTime)")
        
        // Weather-specific details
        switch context.weatherType {
        case .extremeHeat(let temp):
            components.append("🌡️ Extreme heat (\(Int(temp))°C) reducing efficiency")
            if context.travelMode == .car && context.isEV {
                components.append("🔋 EV battery cooling required")
            }
            if context.travelMode == .walking {
                components.append("⚠️ Heat stroke risk - frequent shade stops recommended")
            }
            
        case .heavySnow:
            components.append("❄️ Heavy snow conditions on route")
            components.append("🛣️ Road clearing operations in progress")
            
        case .blizzard:
            components.append("🌨️ BLIZZARD conditions - VISIBILITY EXTREMELY LOW")
            components.append("🚫 Consider postponing travel")
            
        case .severeStorm:
            components.append("⛈️ Severe thunderstorms with lightning")
            components.append("⚡ Safe stopping locations identified")
            
        case .gridlock:
            components.append("🚗 Metropolitan gridlock: 2.2x normal traffic")
            components.append("📍 Alternative routes being calculated")
            
        case .flooding:
            components.append("🌊 Road flooding reported")
            components.append("🔄 Rerouting to avoid affected areas")
            
        case .highWinds(let speed):
            components.append("💨 Sustained winds \(Int(speed)) km/h")
            components.append("⚠️ Crosswind hazard for high-profile vehicles")
            
        default:
            components.append("🌤️ Weather and traffic conditions have changed")
        }
        
        // Add recommendation
        if let recommendation = buildRecommendation(for: context) {
            components.append("\n💡 \(recommendation)")
        }
        
        // Footer with sentinel protocol
        components.append("\n🛡️ Sentinel Alert - High-value notification")
        
        return components.joined(separator: "\n")
    }
    
    // MARK: - Recommendations
    
    private func buildRecommendation(for context: NotificationContext) -> String? {
        switch context.weatherType {
        case .extremeHeat:
            if context.travelMode == .car {
                if context.isEV {
                    return "Pre-cool cabin while plugged in to save battery"
                }
                return "Check coolant levels - high heat increases breakdown risk"
            } else if context.travelMode == .walking {
                return "Plan 15-min shade breaks every hour. Carry 500ml+ water."
            }
            
        case .heavySnow, .blizzard:
            return "If travel is essential, pack emergency kit and blankets"
            
        case .severeStorm:
            return "3 safe charging/gas stops identified along route"
            
        case .gridlock:
            return "Depart 45 mins earlier or consider public transit"
            
        case .flooding:
            return "Monitor local emergency broadcasts for road closures"
            
        case .highWinds:
            return "Reduce speed to 80% of limit. Firm grip on steering."
            
        default:
            return "Tap to see updated route and safe stopping points"
        }
    }
    
    // MARK: - Configuration
    
    private func configurePriority(content: UNMutableNotificationContent, severity: SentinelSeverity) {
        // Set interruption level
        if #available(iOS 15.0, *) {
            switch severity {
            case .critical:
                content.interruptionLevel = .critical
                content.relevanceScore = 1.0
            case .high:
                content.interruptionLevel = .timeSensitive
                content.relevanceScore = 0.8
            case .medium:
                content.interruptionLevel = .active
                content.relevanceScore = 0.5
            case .low:
                content.interruptionLevel = .passive
                content.relevanceScore = 0.3
            }
        }
        
        // Configure sound based on severity
        switch severity {
        case .critical:
            content.sound = .defaultCritical
        case .high:
            content.sound = .default
        default:
            content.sound = .default
        }
        
        // Set badge
        content.badge = 1
    }
    
    // MARK: - User Info
    
    private func buildUserInfo(for alert: SentinelAlert, context: NotificationContext) -> [String: Any] {
        var userInfo: [String: Any] = [
            "notification_type": "sentinel_v3",
            "alert_id": alert.id,
            "severity": alert.severity.rawValue,
            "timestamp": alert.timestamp.timeIntervalSince1970,
            "time_difference": alert.timeDifference,
            "percentage_increase": (alert.timeDifference / alert.originalDuration),
            "original_duration": alert.originalDuration,
            "updated_duration": alert.updatedDuration,
            "travel_mode": context.travelMode.rawValue
        ]
        
        // Add weather-specific info
        switch context.weatherType {
        case .extremeHeat(let temp):
            userInfo["weather_type"] = "extreme_heat"
            userInfo["temperature"] = temp
            
        case .heavySnow:
            userInfo["weather_type"] = "heavy_snow"
            
        case .blizzard:
            userInfo["weather_type"] = "blizzard"
            
        case .severeStorm:
            userInfo["weather_type"] = "severe_storm"
            
        case .gridlock:
            userInfo["weather_type"] = "gridlock"
            
        case .flooding:
            userInfo["weather_type"] = "flooding"
            
        case .highWinds(let speed):
            userInfo["weather_type"] = "high_winds"
            userInfo["wind_speed"] = speed
            
        default:
            userInfo["weather_type"] = "general"
        }
        
        return userInfo
    }
    
    // MARK: - Formatting Helpers
    
    private func formatTimeDifference(_ difference: TimeInterval) -> String {
        let minutes = Int(difference) / 60
        
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        } else {
            return "\(minutes) min"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
    
    // MARK: - Short Format (for Watch/Widget)
    
    func formatShortNotification(
        for alert: SentinelAlert,
        context: NotificationContext
    ) -> (title: String, body: String) {
        let addedTime = formatTimeDifference(alert.timeDifference)
        
        let title: String
        switch context.weatherType {
        case .extremeHeat(let temp):
            title = "🌡️ +\(addedTime) (\(Int(temp))°C)"
        case .heavySnow:
            title = "❄️ +\(addedTime) Snow"
        case .blizzard:
            title = "🌨️ +\(addedTime) BLIZZARD"
        case .severeStorm:
            title = "⛈️ +\(addedTime) Storm"
        case .gridlock:
            title = "🚗 +\(addedTime) Traffic"
        default:
            title = "⚠️ +\(addedTime) Delay"
        }
        
        let body = "Was: \(formatDuration(alert.originalDuration)) → Now: \(formatDuration(alert.updatedDuration))"
        
        return (title, body)
    }
}

// MARK: - Supporting Types

struct NotificationContext: Sendable {
    let weatherType: NotificationWeatherType
    let travelMode: TravelMode
    let isEV: Bool
    let hasSafeStops: Bool
    let alternativeRoutesAvailable: Bool
}

enum NotificationWeatherType: Sendable {
    case extremeHeat(temperature: Double)
    case heavySnow
    case blizzard
    case severeStorm
    case gridlock
    case flooding
    case highWinds(speed: Double)
    case general(conditions: String)
    
    var displayName: String {
        switch self {
        case .extremeHeat: return "Extreme Heat"
        case .heavySnow: return "Heavy Snow"
        case .blizzard: return "Blizzard"
        case .severeStorm: return "Severe Storm"
        case .gridlock: return "Gridlock"
        case .flooding: return "Flooding"
        case .highWinds: return "High Winds"
        case .general(let conditions): return conditions
        }
    }
}

// MARK: - Notification Actions

enum SentinelNotificationAction: String {
    case viewRoute = "VIEW_ROUTE"
    case findAlternative = "FIND_ALTERNATIVE"
    case delayDeparture = "DELAY_DEPARTURE"
    case dismiss = "DISMISS"
    
    var title: String {
        switch self {
        case .viewRoute: return "View Updated Route"
        case .findAlternative: return "Find Safer Route"
        case .delayDeparture: return "Delay Departure"
        case .dismiss: return "Dismiss"
        }
    }
}

// MARK: - Preview Content
extension SentinelNotificationFormatter {
    static var previewContexts: [NotificationContext] {
        [
            NotificationContext(
                weatherType: .extremeHeat(temperature: 42),
                travelMode: .car,
                isEV: true,
                hasSafeStops: true,
                alternativeRoutesAvailable: false
            ),
            NotificationContext(
                weatherType: .heavySnow,
                travelMode: .car,
                isEV: false,
                hasSafeStops: false,
                alternativeRoutesAvailable: true
            ),
            NotificationContext(
                weatherType: .blizzard,
                travelMode: .walking,
                isEV: false,
                hasSafeStops: false,
                alternativeRoutesAvailable: false
            ),
            NotificationContext(
                weatherType: .gridlock,
                travelMode: .car,
                isEV: false,
                hasSafeStops: true,
                alternativeRoutesAvailable: true
            )
        ]
    }
}
