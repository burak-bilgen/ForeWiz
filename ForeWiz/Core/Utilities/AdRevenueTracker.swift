import Foundation
import OSLog

// MARK: - Ad Revenue Tracker
/// Tracks ad revenue events for analytics and optimization.
/// Provides eCPM and revenue-per-unit calculations.
@MainActor
final class AdRevenueTracker {
    static let shared = AdRevenueTracker()
    
    private var impressionsByUnit: [AdManager.AdUnit: Int] = [:]
    private var clicksByUnit: [AdManager.AdUnit: Int] = [:]
    private var estimatedRevenueByUnit: [AdManager.AdUnit: Double] = [:]
    
    private init() {}
    
    /// Record an ad impression (called by AdMob delegate callbacks)
    func recordImpression(unit: AdManager.AdUnit) {
        impressionsByUnit[unit, default: 0] += 1
        AppLogger.analytics.info("[Revenue] Impression: \(unit.rawValue)")
    }
    
    /// Record an ad click
    func recordClick(unit: AdManager.AdUnit) {
        clicksByUnit[unit, default: 0] += 1
        AppLogger.analytics.info("[Revenue] Click: \(unit.rawValue)")
    }
    
    /// Set estimated revenue for a unit (from AdMob SDK callback)
    func recordEstimatedRevenue(unit: AdManager.AdUnit, revenue: Double) {
        estimatedRevenueByUnit[unit, default: 0] += revenue
        AppLogger.analytics.info("[Revenue] Estimated revenue for \(unit.rawValue, privacy: .private): $\(revenue, privacy: .private)")
    }
    
    // MARK: - Metrics
    
    /// Total estimated revenue this session
    var totalEstimatedRevenue: Double {
        estimatedRevenueByUnit.values.reduce(0, +)
    }
    
    /// eCPM (effective cost per mille) across all units
    var eCPM: Double {
        let totalImpressions = impressionsByUnit.values.reduce(0, +)
        guard totalImpressions > 0 else { return 0 }
        return (totalEstimatedRevenue / Double(totalImpressions)) * 1000
    }
    
    /// Get stats for a specific unit
    func stats(for unit: AdManager.AdUnit) -> (impressions: Int, clicks: Int, revenue: Double) {
        (
            impressions: impressionsByUnit[unit] ?? 0,
            clicks: clicksByUnit[unit] ?? 0,
            revenue: estimatedRevenueByUnit[unit] ?? 0
        )
    }
    
    // MARK: - Debug
    
    func debugInfo() -> String {
        var info = "=== Ad Revenue Tracker ===\n"
        info += "Total Est. Revenue: $\(String(format: "%.4f", totalEstimatedRevenue))\n"
        info += "eCPM: $\(String(format: "%.2f", eCPM))\n\n"
        for unit in AdManager.AdUnit.allCases {
            let s = stats(for: unit)
            info += "\(unit.rawValue): \(s.impressions) impressions, \(s.clicks) clicks, $\(String(format: "%.4f", s.revenue))\n"
        }
        return info
    }
    
    /// Reset all counters
    func reset() {
        impressionsByUnit.removeAll()
        clicksByUnit.removeAll()
        estimatedRevenueByUnit.removeAll()
    }
}
