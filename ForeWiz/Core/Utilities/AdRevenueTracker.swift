import Foundation
import OSLog

// MARK: - Ad Revenue Tracker
/// Tracks ad revenue, impressions, clicks, and performance metrics.
/// Provides daily/weekly/monthly revenue summaries for analytics.
@MainActor
final class AdRevenueTracker {
    static let shared = AdRevenueTracker()
    
    // MARK: - Revenue Event
    
    struct RevenueEvent {
        let adUnit: AdManager.AdUnit
        let timestamp: Date
        let revenue: Double
        let currency: String
        let precision: Precision
        
        enum Precision: String {
            case estimated
            case publisherProvided
            case exact
        }
    }
    
    // MARK: - Daily Summary
    
    struct DailySummary {
        let date: Date
        let impressions: Int
        let clicks: Int
        let revenue: Double
        let ctr: Double
        let eCPM: Double
        
        var formattedRevenue: String {
            String(format: "$%.2f", revenue)
        }
        
        var formattedCTR: String {
            String(format: "%.2f%%", ctr)
        }
        
        var formattedECPM: String {
            String(format: "$%.2f", eCPM)
        }
    }
    
    // MARK: - State
    
    private var todayEvents: [RevenueEvent] = []
    private var todayImpressions = 0
    private var todayClicks = 0
    private var todayRevenue: Double = 0
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Tracking
    
    /// Record an ad impression with estimated revenue
    func recordImpression(
        unit: AdManager.AdUnit,
        estimatedRevenue: Double = 0.001
    ) {
        todayImpressions += 1
        todayRevenue += estimatedRevenue
        
        let event = RevenueEvent(
            adUnit: unit,
            timestamp: Date(),
            revenue: estimatedRevenue,
            currency: "USD",
            precision: .estimated
        )
        todayEvents.append(event)
        
        AppLogger.analytics.info("[Revenue] Impression: \(unit.rawValue) ($\(String(format: "%.4f", estimatedRevenue)))")
    }
    
    /// Record an ad click with estimated revenue
    func recordClick(
        unit: AdManager.AdUnit,
        estimatedRevenue: Double = 0.05
    ) {
        todayClicks += 1
        todayRevenue += estimatedRevenue
        
        let event = RevenueEvent(
            adUnit: unit,
            timestamp: Date(),
            revenue: estimatedRevenue,
            currency: "USD",
            precision: .estimated
        )
        todayEvents.append(event)
        
        AppLogger.analytics.info("[Revenue] Click: \(unit.rawValue) ($\(String(format: "%.4f", estimatedRevenue)))")
    }
    
    /// Record exact revenue from ad network callback
    func recordExactRevenue(
        unit: AdManager.AdUnit,
        revenue: Double,
        currency: String = "USD"
    ) {
        todayRevenue += revenue
        
        let event = RevenueEvent(
            adUnit: unit,
            timestamp: Date(),
            revenue: revenue,
            currency: currency,
            precision: .exact
        )
        todayEvents.append(event)
        
        AppLogger.analytics.info("[Revenue] Exact: \(unit.rawValue) (\(currency) \(String(format: "%.4f", revenue)))")
    }
    
    // MARK: - Summary
    
    /// Get today's revenue summary
    func todaySummary() -> DailySummary {
        let ctr = todayImpressions > 0 ? (Double(todayClicks) / Double(todayImpressions)) * 100 : 0
        let eCPM = todayImpressions > 0 ? (todayRevenue / Double(todayImpressions)) * 1000 : 0
        
        return DailySummary(
            date: Date(),
            impressions: todayImpressions,
            clicks: todayClicks,
            revenue: todayRevenue,
            ctr: ctr,
            eCPM: eCPM
        )
    }
    
    /// Get revenue breakdown by ad unit
    func revenueByUnit() -> [AdManager.AdUnit: Double] {
        var breakdown: [AdManager.AdUnit: Double] = [:]
        
        for event in todayEvents {
            breakdown[event.adUnit, default: 0] += event.revenue
        }
        
        return breakdown
    }
    
    /// Get impression breakdown by ad unit
    func impressionsByUnit() -> [AdManager.AdUnit: Int] {
        var breakdown: [AdManager.AdUnit: Int] = [:]
        
        for event in todayEvents {
            breakdown[event.adUnit, default: 0] += 1
        }
        
        return breakdown
    }
    
    // MARK: - Reset
    
    /// Reset daily counters (call at midnight)
    func resetDailyCounters() {
        todayEvents.removeAll()
        todayImpressions = 0
        todayClicks = 0
        todayRevenue = 0
        
        AppLogger.app.info("[Revenue] Daily counters reset")
    }
    
    // MARK: - Debug
    
    func debugInfo() -> String {
        let summary = todaySummary()
        var info = "=== Revenue Debug ===\n"
        info += "Today's Revenue: \(summary.formattedRevenue)\n"
        info += "Impressions: \(summary.impressions)\n"
        info += "Clicks: \(summary.clicks)\n"
        info += "CTR: \(summary.formattedCTR)\n"
        info += "eCPM: \(summary.formattedECPM)\n\n"
        
        info += "By Unit:\n"
        for (unit, revenue) in revenueByUnit() {
            info += "  \(unit.rawValue): $\(String(format: "%.4f", revenue))\n"
        }
        
        return info
    }
}
