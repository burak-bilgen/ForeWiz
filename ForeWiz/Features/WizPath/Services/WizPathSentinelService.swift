import Foundation
import UserNotifications
import OSLog

// MARK: - Sentinel Service
/// High-value notification system for critical route changes
/// Only fires alerts for life-altering conditions (>30min delay or >40% time increase)
@MainActor
final class WizPathSentinelService {
    static let shared = WizPathSentinelService()
    
    // MARK: - Thresholds
    struct Thresholds {
        /// Minimum delay to trigger sentinel (30 minutes)
        static let minimumDelayMinutes: Double = 30
        
        /// Minimum percentage increase to trigger sentinel (40%)
        static let minimumPercentageIncrease: Double = 0.40
        
        /// Maximum notifications per hour (noise reduction)
        static let maxNotificationsPerHour: Int = 3
        
        /// Cooldown period between similar alerts (15 minutes)
        static let cooldownMinutes: Double = 15
    }
    
    // MARK: - Dependencies
    private let notificationCenter: UNUserNotificationCenter
    private let analytics: WizPathAnalytics
    
    // MARK: - State
    private var lastAlertTimestamps: [String: Date] = [:]
    private var notificationCountThisHour: Int = 0
    private var hourStartTime: Date = Date()
    
    private init(
        notificationCenter: UNUserNotificationCenter = .current(),
        analytics: WizPathAnalytics = .shared
    ) {
        self.notificationCenter = notificationCenter
        self.analytics = analytics
    }
    
    // MARK: - Sentinel Evaluation
    
    /// Evaluate if a route change warrants a sentinel alert
    func evaluateRouteChange(
        originalRoute: WizPathRoute,
        updatedRoute: WizPathRoute,
        weatherContext: WeatherContext
    ) -> SentinelDecision {
        // Reset hourly counter if needed
        resetHourlyCounterIfNeeded()
        
        // Check rate limiting
        if notificationCountThisHour >= Thresholds.maxNotificationsPerHour {
            return .suppressed(reason: .rateLimited)
        }
        
        // Calculate time difference
        let timeDifference = updatedRoute.totalDuration - originalRoute.totalDuration
        let percentageIncrease = timeDifference / originalRoute.totalDuration
        
        // Check if thresholds are met
        let meetsDelayThreshold = timeDifference >= (Thresholds.minimumDelayMinutes * 60)
        let meetsPercentageThreshold = percentageIncrease >= Thresholds.minimumPercentageIncrease
        
        // Generate alert ID based on route signature
        let alertID = generateAlertID(for: updatedRoute, context: weatherContext)
        
        // Check cooldown
        if let lastAlert = lastAlertTimestamps[alertID],
           Date().timeIntervalSince(lastAlert) < (Thresholds.cooldownMinutes * 60) {
            return .suppressed(reason: .cooldownActive)
        }
        
        // Determine if this is sentinel-worthy
        if meetsDelayThreshold || meetsPercentageThreshold {
            // Calculate severity
            let severity = calculateSeverity(
                timeDifference: timeDifference,
                percentageIncrease: percentageIncrease,
                weatherContext: weatherContext
            )
            
            // Build alert content
            let alert = buildSentinelAlert(
                originalRoute: originalRoute,
                updatedRoute: updatedRoute,
                weatherContext: weatherContext,
                severity: severity,
                timeDifference: timeDifference,
                percentageIncrease: percentageIncrease
            )
            
            return .trigger(alert: alert)
        }
        
        return .suppressed(reason: .belowThreshold)
    }
    
    // MARK: - Alert Dispatch
    
    /// Dispatch a sentinel notification
    func dispatchSentinelAlert(_ alert: SentinelAlert) async {
        // Request authorization if needed
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            AppLogger.notifications.warning("Sentinel alert blocked: no notification permission")
            return
        }
        
        // Build notification content
        let content = buildNotificationContent(for: alert)
        
        // Create trigger (immediate)
        let request = UNNotificationRequest(
            identifier: alert.id,
            content: content,
            trigger: nil // Immediate
        )
        
        do {
            try await notificationCenter.add(request)
            
            // Update tracking
            lastAlertTimestamps[alert.signature] = Date()
            notificationCountThisHour += 1
            
            // Log analytics
            analytics.trackSentinelTriggered(alert)
            
            AppLogger.notifications.info("Sentinel alert dispatched: \(alert.title)")
        } catch {
            AppLogger.notifications.error("Failed to dispatch sentinel: \(error)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func resetHourlyCounterIfNeeded() {
        let hourAgo = Date().addingTimeInterval(-3600)
        if hourStartTime < hourAgo {
            notificationCountThisHour = 0
            hourStartTime = Date()
        }
    }
    
    private func generateAlertID(for route: WizPathRoute, context: WeatherContext) -> String {
        let routeSignature = "\(route.origin.latitude),\(route.origin.longitude)|\(route.destination.latitude),\(route.destination.longitude)"
        let weatherSignature = context.primaryHazard?.rawValue ?? "general"
        return "sentinel.\(routeSignature).\(weatherSignature)"
    }
    
    private func calculateSeverity(
        timeDifference: TimeInterval,
        percentageIncrease: Double,
        weatherContext: WeatherContext
    ) -> SentinelSeverity {
        let delayMinutes = timeDifference / 60
        
        // Critical: >2 hours delay or >100% increase
        if delayMinutes > 120 || percentageIncrease > 1.0 {
            return .critical
        }
        
        // High: >60 min delay or >70% increase, or extreme weather
        if delayMinutes > 60 || percentageIncrease > 0.70 || weatherContext.isExtreme {
            return .high
        }
        
        // Medium: >30 min delay or >40% increase
        if delayMinutes > 30 || percentageIncrease > 0.40 {
            return .medium
        }
        
        return .low
    }
    
    private func buildSentinelAlert(
        originalRoute: WizPathRoute,
        updatedRoute: WizPathRoute,
        weatherContext: WeatherContext,
        severity: SentinelSeverity,
        timeDifference: TimeInterval,
        percentageIncrease: Double
    ) -> SentinelAlert {
        let id = UUID().uuidString
        let signature = generateAlertID(for: updatedRoute, context: weatherContext)
        
        // Format time strings
        let originalDuration = formatDuration(originalRoute.totalDuration)
        let updatedDuration = formatDuration(updatedRoute.totalDuration)
        let addedTime = formatDuration(timeDifference)
        
        // Build title based on primary cause
        let title: String
        let body: String
        
        switch weatherContext.primaryHazard {
        case .extremeHeat:
            title = L10n.formatted("sentinel_title_heat", addedTime)
            body = L10n.formatted("sentinel_body_heat", originalDuration, updatedDuration, Int(percentageIncrease * 100))
            
        case .heavySnow, .blizzard:
            title = L10n.formatted("sentinel_title_snow", addedTime)
            body = L10n.formatted("sentinel_body_snow", originalDuration, updatedDuration)
            
        case .severeStorm:
            title = L10n.formatted("sentinel_title_storm", addedTime)
            body = L10n.formatted("sentinel_body_storm", originalDuration, updatedDuration)
            
        case .gridlock:
            title = L10n.formatted("sentinel_title_gridlock", addedTime)
            body = L10n.formatted("sentinel_body_gridlock", originalDuration, updatedDuration)
            
        default:
            title = L10n.formatted("sentinel_title_general", addedTime)
            body = L10n.formatted("sentinel_body_general", originalDuration, updatedDuration, Int(percentageIncrease * 100))
        }
        
        return SentinelAlert(
            id: id,
            signature: signature,
            title: title,
            body: body,
            severity: severity,
            originalDuration: originalRoute.totalDuration,
            updatedDuration: updatedRoute.totalDuration,
            weatherContext: weatherContext,
            timestamp: Date()
        )
    }
    
    private func buildNotificationContent(for alert: SentinelAlert) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.body
        content.sound = .default
        content.badge = 1
        
        // Set interruption level based on severity
        if #available(iOS 15.0, *) {
            switch alert.severity {
            case .critical:
                content.interruptionLevel = .critical
            case .high:
                content.interruptionLevel = .timeSensitive
            default:
                content.interruptionLevel = .active
            }
        }
        
        // Add user info for deep linking
        content.userInfo = [
            "type": "sentinel_alert",
            "alert_id": alert.id,
            "severity": alert.severity.rawValue,
            "timestamp": alert.timestamp.timeIntervalSince1970
        ]
        
        return content
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
}

// MARK: - Supporting Types

enum SentinelDecision: Sendable {
    case trigger(alert: SentinelAlert)
    case suppressed(reason: SuppressionReason)
}

enum SuppressionReason: Sendable {
    case belowThreshold
    case rateLimited
    case cooldownActive
    case userDisabled
    
    var description: String {
        switch self {
        case .belowThreshold: return "Delay below sentinel threshold"
        case .rateLimited: return "Rate limit exceeded (max 3/hour)"
        case .cooldownActive: return "Cooldown period active (15 min)"
        case .userDisabled: return "User disabled notifications"
        }
    }
}

struct SentinelAlert: Sendable {
    let id: String
    let signature: String
    let title: String
    let body: String
    let severity: SentinelSeverity
    let originalDuration: TimeInterval
    let updatedDuration: TimeInterval
    let weatherContext: WeatherContext
    let timestamp: Date
    
    var timeDifference: TimeInterval {
        updatedDuration - originalDuration
    }
}

enum SentinelSeverity: String, Sendable {
    case low, medium, high, critical
}

struct WeatherContext: Sendable {
    let primaryHazard: WeatherHazardType?
    let temperature: Double?
    let conditions: [SegmentWeatherCondition]
    let isExtreme: Bool
}

enum WeatherHazardType: String, Sendable {
    case extremeHeat
    case heavySnow
    case blizzard
    case severeStorm
    case gridlock
    case flooding
}

// MARK: - Analytics

@MainActor
final class WizPathAnalytics {
    static let shared = WizPathAnalytics()
    
    func trackSentinelTriggered(_ alert: SentinelAlert) {
        AppLogger.analytics.info("Sentinel triggered: \(alert.severity) - \(alert.title)")
        // In production: Send to analytics backend
    }
}
