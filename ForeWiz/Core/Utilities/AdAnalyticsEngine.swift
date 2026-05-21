import Foundation
import OSLog

// MARK: - Ad Analytics Engine
/// Comprehensive analytics engine for tracking ad performance,
/// user engagement, and revenue optimization.
@MainActor
final class AdAnalyticsEngine {
    static let shared = AdAnalyticsEngine()
    
    // MARK: - Event Types
    
    enum EventType: String {
        case impression
        case click
        case reward
        case error
        case loaded
        case failed
        case dismissed
        case skipped
    }
    
    // MARK: - Analytics Event
    
    struct Event {
        let type: EventType
        let unit: AdManager.AdUnit
        let timestamp: Date
        let metadata: [String: String]
        let revenue: Double?
        let sessionID: String
    }
    
    // MARK: - Performance Metrics
    
    struct Metrics {
        let totalImpressions: Int
        let totalClicks: Int
        let totalRevenue: Double
        let ctr: Double
        let eCPM: Double
        let fillRate: Double
        let errorRate: Double
        let avgLoadTime: TimeInterval
        let revenueByUnit: [AdManager.AdUnit: Double]
        let impressionsByUnit: [AdManager.AdUnit: Int]
        
        var formattedRevenue: String { String(format: "$%.2f", totalRevenue) }
        var formattedCTR: String { String(format: "%.2f%%", ctr) }
        var formattedECPM: String { String(format: "$%.2f", eCPM) }
        var formattedFillRate: String { String(format: "%.1f%%", fillRate) }
        var formattedErrorRate: String { String(format: "%.1f%%", errorRate) }
    }
    
    // MARK: - State
    
    private var events: [Event] = []
    private var sessionID: String = UUID().uuidString
    private var loadStartTimes: [AdManager.AdUnit: Date] = [:]
    private var loadTimes: [TimeInterval] = []
    private var totalLoadAttempts = 0
    private var totalLoadSuccesses = 0
    private var totalLoadFailures = 0
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Event Tracking
    
    /// Record an ad event
    func recordEvent(
        _ type: EventType,
        unit: AdManager.AdUnit,
        metadata: [String: String] = [:],
        revenue: Double? = nil
    ) {
        let event = Event(
            type: type,
            unit: unit,
            timestamp: Date(),
            metadata: metadata,
            revenue: revenue,
            sessionID: sessionID
        )
        events.append(event)
        
        // Track load times
        if type == .loaded, let startTime = loadStartTimes[unit] {
            let loadTime = Date().timeIntervalSince(startTime)
            loadTimes.append(loadTime)
            loadStartTimes[unit] = nil
            totalLoadSuccesses += 1
        }
        
        if type == .failed {
            totalLoadFailures += 1
            loadStartTimes[unit] = nil
        }
        
        totalLoadAttempts += 1
        
        AppLogger.analytics.info("[AdAnalytics] \(type.rawValue) - \(unit.rawValue) (session: \(self.sessionID.prefix(8)))")
    }
    
    /// Mark ad load start
    func markLoadStart(_ unit: AdManager.AdUnit) {
        loadStartTimes[unit] = Date()
    }
    
    // MARK: - Metrics Calculation
    
    /// Calculate current metrics
    func calculateMetrics() -> Metrics {
        let impressions = events.filter { $0.type == .impression }
        let clicks = events.filter { $0.type == .click }
        let _ = events.filter { $0.type == .error }
        let _ = events.filter { $0.type == .reward }
        
        let totalImpressions = impressions.count
        let totalClicks = clicks.count
        let totalRevenue = events.compactMap { $0.revenue }.reduce(0, +)
        
        let ctr = totalImpressions > 0 ? (Double(totalClicks) / Double(totalImpressions)) * 100 : 0
        let eCPM = totalImpressions > 0 ? (totalRevenue / Double(totalImpressions)) * 1000 : 0
        
        let fillRate = totalLoadAttempts > 0 ? (Double(totalLoadSuccesses) / Double(totalLoadAttempts)) * 100 : 0
        let errorRate = totalLoadAttempts > 0 ? (Double(totalLoadFailures) / Double(totalLoadAttempts)) * 100 : 0
        let avgLoadTime = loadTimes.isEmpty ? 0 : loadTimes.reduce(0, +) / Double(loadTimes.count)
        
        var revenueByUnit: [AdManager.AdUnit: Double] = [:]
        var impressionsByUnit: [AdManager.AdUnit: Int] = [:]
        
        for event in events {
            if let revenue = event.revenue {
                revenueByUnit[event.unit, default: 0] += revenue
            }
            if event.type == .impression {
                impressionsByUnit[event.unit, default: 0] += 1
            }
        }
        
        return Metrics(
            totalImpressions: totalImpressions,
            totalClicks: totalClicks,
            totalRevenue: totalRevenue,
            ctr: ctr,
            eCPM: eCPM,
            fillRate: fillRate,
            errorRate: errorRate,
            avgLoadTime: avgLoadTime,
            revenueByUnit: revenueByUnit,
            impressionsByUnit: impressionsByUnit
        )
    }
    
    // MARK: - Session Management
    
    /// Start a new analytics session
    func startNewSession() {
        sessionID = UUID().uuidString
        AppLogger.app.info("[AdAnalytics] New session: \(self.sessionID)")
    }
    
    /// Get current session ID
    func currentSessionID() -> String {
        sessionID
    }
    
    // MARK: - Export
    
    /// Export events for the given time range
    func exportEvents(since: Date) -> [Event] {
        events.filter { $0.timestamp >= since }
    }
    
    /// Export metrics summary
    func exportSummary() -> String {
        let metrics = calculateMetrics()
        
        var summary = "=== Ad Analytics Summary ===\n"
        summary += "Session: \(sessionID.prefix(8))\n"
        summary += "Total Events: \(events.count)\n\n"
        summary += "Impressions: \(metrics.totalImpressions)\n"
        summary += "Clicks: \(metrics.totalClicks)\n"
        summary += "Rewards: \(events.filter { $0.type == .reward }.count)\n"
        summary += "Revenue: \(metrics.formattedRevenue)\n"
        summary += "CTR: \(metrics.formattedCTR)\n"
        summary += "eCPM: \(metrics.formattedECPM)\n"
        summary += "Fill Rate: \(metrics.formattedFillRate)\n"
        summary += "Error Rate: \(metrics.formattedErrorRate)\n"
        summary += "Avg Load Time: \(String(format: "%.2f", metrics.avgLoadTime))s\n\n"
        
        summary += "Revenue by Unit:\n"
        for (unit, revenue) in metrics.revenueByUnit {
            summary += "  \(unit.rawValue): $\(String(format: "%.4f", revenue))\n"
        }
        
        summary += "\nImpressions by Unit:\n"
        for (unit, count) in metrics.impressionsByUnit {
            summary += "  \(unit.rawValue): \(count)\n"
        }
        
        return summary
    }
    
    // MARK: - Reset
    
    /// Reset all analytics data
    func reset() {
        events.removeAll()
        loadTimes.removeAll()
        loadStartTimes.removeAll()
        totalLoadAttempts = 0
        totalLoadSuccesses = 0
        totalLoadFailures = 0
        startNewSession()
    }
}
