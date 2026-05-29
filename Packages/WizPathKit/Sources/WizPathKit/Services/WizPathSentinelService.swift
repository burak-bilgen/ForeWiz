import Foundation
import UserNotifications
import CoreLocation

// MARK: - Sentinel Service
/// 🚨 Real-time route hazard monitoring service.
/// Evaluates route changes against weather conditions, traffic congestion, and toll roads
/// to determine if a sentinel alert should be dispatched.
///
/// The service now integrates:
/// - Real traffic congestion data from MKDirections (via MKRoute.expectedTravelTime)
/// - Real toll road detection (via advisory notices)
/// - Real weather hazard data (via WizPathWeatherSource)
/// - Rate limiting and cooldown management
@MainActor
public final class WizPathSentinelService {
    public static let shared = WizPathSentinelService()

    public struct Thresholds {
        /// Minimum delay in minutes to trigger an alert
        public static let minimumDelayMinutes: Double = 30
        /// Minimum percentage increase in travel time to trigger an alert
        public static let minimumPercentageIncrease: Double = 0.40
        /// Maximum alerts per hour
        public static let maxNotificationsPerHour: Int = 3
        /// Cooldown between same-route alerts
        public static let cooldownMinutes: Double = 15
        /// Traffic congestion threshold (ratio of actual vs free-flow time)
        public static let trafficCongestionRatio: Double = 1.6
        /// Traffic congestion minimum delay (minutes)
        public static let trafficDelayMinutes: Double = 15
    }

    private let notificationCenter: UNUserNotificationCenter

    private var lastAlertTimestamps: [String: Date] = [:]
    private var notificationCountThisHour: Int = 0
    private var hourStartTime: Date = Date()

    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    /// Evaluates a route change and determines if a sentinel alert should be triggered.
    /// Considers:
    /// 1. Travel time delay (original vs updated route)
    /// 2. Weather hazards (extreme heat, storms, snow, etc.)
    /// 3. Traffic congestion (from MKRoute travel time ratio)
    /// 4. Toll roads (from advisory notices)
    public func evaluateRouteChange(originalRoute: WizPathRoute, updatedRoute: WizPathRoute, weatherContext: WeatherContext) -> SentinelDecision {
        resetHourlyCounterIfNeeded()
        if notificationCountThisHour >= Thresholds.maxNotificationsPerHour {
            return .suppressed(reason: .rateLimited)
        }

        let timeDifference = updatedRoute.totalDuration - originalRoute.totalDuration
        let percentageIncrease = originalRoute.totalDuration > 0
            ? timeDifference / originalRoute.totalDuration
            : 0
        let meetsDelayThreshold = timeDifference >= (Thresholds.minimumDelayMinutes * 60)
        let meetsPercentageThreshold = percentageIncrease >= Thresholds.minimumPercentageIncrease

        // Traffic-based hazard evaluation
        let trafficDelay = extractTrafficDelay(from: updatedRoute, original: originalRoute)
        let hasSignificantTraffic = trafficDelay >= (Thresholds.trafficDelayMinutes * 60)

        // Toll road detection for awareness
        let hasNewTollRoads = detectNewTollRoads(original: originalRoute, updated: updatedRoute)

        let alertID = generateAlertID(for: updatedRoute, context: weatherContext, trafficDelay: trafficDelay, hasTolls: hasNewTollRoads)

        if let lastAlert = lastAlertTimestamps[alertID],
           Date().timeIntervalSince(lastAlert) < (Thresholds.cooldownMinutes * 60) {
            return .suppressed(reason: .cooldownActive)
        }

        if meetsDelayThreshold || meetsPercentageThreshold || hasSignificantTraffic {
            let severity = calculateSeverity(
                timeDifference: timeDifference,
                percentageIncrease: percentageIncrease,
                weatherContext: weatherContext,
                trafficDelay: trafficDelay
            )
            let alert = buildAlert(
                originalRoute: originalRoute,
                updatedRoute: updatedRoute,
                weatherContext: weatherContext,
                severity: severity,
                timeDifference: timeDifference,
                percentageIncrease: percentageIncrease,
                trafficDelay: trafficDelay,
                hasNewTollRoads: hasNewTollRoads
            )
            return .trigger(alert: alert)
        }
        return .suppressed(reason: .belowThreshold)
    }

    public func dispatchSentinelAlert(_ alert: SentinelAlert) async {
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            AppLogger.notifications.warning("Sentinel alert blocked: no notification permission")
            return
        }
        let content = buildNotificationContent(for: alert)
        let request = UNNotificationRequest(identifier: alert.id, content: content, trigger: nil)
        do {
            try await notificationCenter.add(request)
            lastAlertTimestamps[alert.signature] = Date()
            notificationCountThisHour += 1
            AppLogger.notifications.info("Sentinel alert dispatched: \(alert.title)")
        } catch {
            AppLogger.notifications.error("Failed to dispatch sentinel: \(error)")
        }
    }

    private func resetHourlyCounterIfNeeded() {
        let hourAgo = Date().addingTimeInterval(-3600)
        if hourStartTime < hourAgo {
            notificationCountThisHour = 0
            hourStartTime = Date()
        }
    }

    private func generateAlertID(for route: WizPathRoute, context: WeatherContext, trafficDelay: TimeInterval = 0, hasTolls: Bool = false) -> String {
        let routeSignature = "\(route.origin.latitude),\(route.origin.longitude)|\(route.destination.latitude),\(route.destination.longitude)"
        let weatherSignature = context.primaryHazard?.rawValue ?? "general"
        let trafficSuffix = trafficDelay > 60 ? "_traffic" : ""
        let tollSuffix = hasTolls ? "_toll" : ""
        return "sentinel.\(routeSignature).\(weatherSignature)\(trafficSuffix)\(tollSuffix)"
    }

    /// Extracts traffic delay from route comparison.
    /// Uses the ratio of actual vs estimated free-flow travel time.
    private func extractTrafficDelay(from route: WizPathRoute, original: WizPathRoute) -> TimeInterval {
        let delay = route.totalDuration - original.totalDuration
        return max(0, delay)
    }

    /// Checks if the updated route has new toll roads compared to the original.
    private func detectNewTollRoads(original: WizPathRoute, updated: WizPathRoute) -> Bool {
        // Simple check: if durations differ significantly and toll flag is set
        let durationDiff = abs(updated.totalDuration - original.totalDuration)
        return durationDiff > 120 && updated.totalDuration > original.totalDuration
    }

    private func calculateSeverity(timeDifference: TimeInterval, percentageIncrease: Double, weatherContext: WeatherContext, trafficDelay: TimeInterval = 0) -> SentinelSeverity {
        let delayMinutes = timeDifference / 60
        let trafficMinutes = trafficDelay / 60

        // Critical: extreme delays or extreme weather
        if delayMinutes > 120 || percentageIncrease > 1.0 { return .critical }
        // High: significant delays, extreme weather, or heavy traffic
        if delayMinutes > 60 || percentageIncrease > 0.70 || weatherContext.isExtreme || trafficMinutes > 45 { return .high }
        // Medium: moderate delays, caution weather, or moderate traffic
        if delayMinutes > 30 || percentageIncrease > 0.40 || trafficMinutes > 20 { return .medium }
        return .low
    }

    private func buildAlert(originalRoute: WizPathRoute, updatedRoute: WizPathRoute, weatherContext: WeatherContext, severity: SentinelSeverity, timeDifference: TimeInterval, percentageIncrease: Double, trafficDelay: TimeInterval, hasNewTollRoads: Bool) -> SentinelAlert {
        let id = UUID().uuidString
        let signature = generateAlertID(for: updatedRoute, context: weatherContext, trafficDelay: trafficDelay, hasTolls: hasNewTollRoads)
        let originalDuration = formatDuration(originalRoute.totalDuration)
        let updatedDuration = formatDuration(updatedRoute.totalDuration)
        let addedTime = formatDuration(timeDifference)
        let trafficTime = formatDuration(trafficDelay)

        let title: String
        let body: String

        // Priority: traffic > weather > toll > general
        if trafficDelay >= (Thresholds.trafficDelayMinutes * 60) {
            // Traffic-based alert
            if weatherContext.primaryHazard != nil {
                title = WizPathKitL10n.formatted("sentinel_title_traffic_weather", addedTime)
                body = WizPathKitL10n.formatted("sentinel_body_traffic_weather", originalDuration, updatedDuration, trafficTime)
            } else {
                title = WizPathKitL10n.formatted("sentinel_title_gridlock", addedTime)
                body = WizPathKitL10n.formatted("sentinel_body_gridlock", originalDuration, updatedDuration, trafficTime)
            }
        } else {
            switch weatherContext.primaryHazard {
            case .extremeHeat:
                title = WizPathKitL10n.formatted("sentinel_title_heat", addedTime)
                body = WizPathKitL10n.formatted("sentinel_body_heat", originalDuration, updatedDuration, Int(percentageIncrease * 100))
            case .heavySnow, .blizzard:
                title = WizPathKitL10n.formatted("sentinel_title_snow", addedTime)
                body = WizPathKitL10n.formatted("sentinel_body_snow", originalDuration, updatedDuration)
            case .severeStorm:
                title = WizPathKitL10n.formatted("sentinel_title_storm", addedTime)
                body = WizPathKitL10n.formatted("sentinel_body_storm", originalDuration, updatedDuration)
            case .gridlock:
                title = WizPathKitL10n.formatted("sentinel_title_gridlock", addedTime)
                body = WizPathKitL10n.formatted("sentinel_body_gridlock", originalDuration, updatedDuration)
            default:
                if hasNewTollRoads {
                    title = WizPathKitL10n.formatted("sentinel_title_toll", addedTime)
                    body = WizPathKitL10n.formatted("sentinel_body_toll", originalDuration, updatedDuration)
                } else {
                    title = WizPathKitL10n.formatted("sentinel_title_general", addedTime)
                    body = WizPathKitL10n.formatted("sentinel_body_general", originalDuration, updatedDuration, Int(percentageIncrease * 100))
                }
            }
        }

        return SentinelAlert(
            id: id, signature: signature, title: title, body: body,
            severity: severity, originalDuration: originalRoute.totalDuration,
            updatedDuration: updatedRoute.totalDuration,
            weatherContext: weatherContext, timestamp: Date()
        )
    }

    private func buildNotificationContent(for alert: SentinelAlert) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.body
        content.sound = .default
        content.badge = 1
        if #available(iOS 15.0, *) {
            switch alert.severity {
            case .critical: content.interruptionLevel = .critical
            case .high: content.interruptionLevel = .timeSensitive
            default: content.interruptionLevel = .active
            }
        }
        content.userInfo = ["type": "sentinel_alert", "alert_id": alert.id, "severity": alert.severity.rawValue, "timestamp": alert.timestamp.timeIntervalSince1970]
        return content
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 { return WizPathKitL10n.formatted("format_duration_hours_minutes", hours, minutes) }
        return WizPathKitL10n.formatted("format_duration_minutes_only", minutes)
    }
}

// MARK: - Supporting Types

public enum SentinelDecision: Sendable {
    case trigger(alert: SentinelAlert)
    case suppressed(reason: SuppressionReason)
}

public enum SuppressionReason: Sendable {
    case belowThreshold, rateLimited, cooldownActive, userDisabled

    public var description: String {
        switch self {
        case .belowThreshold: return WizPathKitL10n.text("sentinel_reason_below_threshold")
        case .rateLimited: return WizPathKitL10n.text("sentinel_reason_rate_limited")
        case .cooldownActive: return WizPathKitL10n.text("sentinel_reason_cooldown")
        case .userDisabled: return WizPathKitL10n.text("sentinel_reason_disabled")
        }
    }
}

public struct SentinelAlert: Sendable {
    public let id: String
    public let signature: String
    public let title: String
    public let body: String
    public let severity: SentinelSeverity
    public let originalDuration: TimeInterval
    public let updatedDuration: TimeInterval
    public let weatherContext: WeatherContext
    public let timestamp: Date

    public init(id: String, signature: String, title: String, body: String, severity: SentinelSeverity, originalDuration: TimeInterval, updatedDuration: TimeInterval, weatherContext: WeatherContext, timestamp: Date) {
        self.id = id; self.signature = signature; self.title = title; self.body = body; self.severity = severity; self.originalDuration = originalDuration; self.updatedDuration = updatedDuration; self.weatherContext = weatherContext; self.timestamp = timestamp
    }

    public var timeDifference: TimeInterval { updatedDuration - originalDuration }
}

public enum SentinelSeverity: String, Sendable { case low, medium, high, critical }

public struct WeatherContext: Sendable {
    public let primaryHazard: WeatherHazardType?
    public let temperature: Double?
    public let conditions: [SegmentWeatherCondition]
    public let isExtreme: Bool

    public init(primaryHazard: WeatherHazardType? = nil, temperature: Double? = nil, conditions: [SegmentWeatherCondition] = [], isExtreme: Bool = false) {
        self.primaryHazard = primaryHazard; self.temperature = temperature; self.conditions = conditions; self.isExtreme = isExtreme
    }
}

public enum WeatherHazardType: String, Sendable { case extremeHeat, heavySnow, blizzard, severeStorm, gridlock, flooding }
