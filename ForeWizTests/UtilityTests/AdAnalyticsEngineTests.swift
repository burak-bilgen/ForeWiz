import Foundation
import Testing
@testable import ForeWiz

@MainActor
struct AdAnalyticsEngineTests {
    let engine = AdAnalyticsEngine.shared
    
    @Test("Initial metrics are zero")
    func initialMetricsZero() {
        engine.reset()
        let metrics = engine.calculateMetrics()
        #expect(metrics.totalImpressions == 0)
        #expect(metrics.totalClicks == 0)
        #expect(metrics.totalRevenue == 0)
        #expect(metrics.ctr == 0)
        #expect(metrics.eCPM == 0)
        #expect(metrics.fillRate == 0)
        #expect(metrics.errorRate == 0)
        #expect(metrics.avgLoadTime == 0)
    }
    
    @Test("recordEvent stores impression events")
    func recordImpressionEvent() {
        engine.reset()
        engine.recordEvent(.impression, unit: .banner)
        
        let metrics = engine.calculateMetrics()
        #expect(metrics.totalImpressions == 1)
        #expect(metrics.impressionsByUnit[.banner] == 1)
    }
    
    @Test("recordEvent stores click events")
    func recordClickEvent() {
        engine.reset()
        engine.recordEvent(.click, unit: .native)
        
        let metrics = engine.calculateMetrics()
        #expect(metrics.totalClicks == 1)
    }
    
    @Test("recordEvent with revenue tracks correctly")
    func recordRevenueEvent() {
        engine.reset()
        engine.recordEvent(.reward, unit: .rewarded, revenue: 0.05)
        engine.recordEvent(.reward, unit: .rewarded, revenue: 0.03)
        
        let metrics = engine.calculateMetrics()
        #expect(metrics.totalRevenue == 0.08)
        #expect(metrics.revenueByUnit[.rewarded] == 0.08)
    }
    
    @Test("CTR is calculated correctly")
    func ctrCalculation() {
        engine.reset()
        for _ in 0..<10 {
            engine.recordEvent(.impression, unit: .banner)
        }
        for _ in 0..<2 {
            engine.recordEvent(.click, unit: .banner)
        }
        
        let metrics = engine.calculateMetrics()
        #expect(metrics.ctr == 20.0) // 2/10 * 100 = 20%
    }
    
    @Test("eCPM is calculated correctly")
    func eCPMCalculation() {
        engine.reset()
        for _ in 0..<100 {
            engine.recordEvent(.impression, unit: .banner)
        }
        engine.recordEvent(.reward, unit: .banner, revenue: 0.50)
        
        let metrics = engine.calculateMetrics()
        #expect(metrics.eCPM == 5.0) // ($0.50/100) * 1000 = $5.00
    }
    
    @Test("startNewSession changes session ID")
    func startNewSessionChangesID() {
        let firstID = engine.currentSessionID()
        engine.startNewSession()
        let secondID = engine.currentSessionID()
        
        #expect(firstID != secondID)
    }
    
    @Test("exportEvents filters by date")
    func exportEventsByDate() {
        engine.reset()
        engine.recordEvent(.impression, unit: .banner)
        
        // Export events since 1 hour ago should include our event
        let events = engine.exportEvents(since: Date().addingTimeInterval(-3600))
        #expect(events.count >= 1)
        
        // Export events since 1 hour from now should be empty
        let futureEvents = engine.exportEvents(since: Date().addingTimeInterval(3600))
        #expect(futureEvents.isEmpty)
    }
    
    @Test("markLoadStart and loaded event track load time")
    func markLoadStartTracksTime() {
        engine.reset()
        engine.markLoadStart(.interstitial)
        engine.recordEvent(.loaded, unit: .interstitial)
        
        let metrics = engine.calculateMetrics()
        #expect(metrics.avgLoadTime >= 0)
    }
    
    @Test("reset clears all analytics data")
    func resetClearsData() {
        engine.recordEvent(.impression, unit: .banner)
        engine.recordEvent(.click, unit: .banner)
        engine.reset()
        
        let metrics = engine.calculateMetrics()
        #expect(metrics.totalImpressions == 0)
        #expect(metrics.totalClicks == 0)
        #expect(metrics.totalRevenue == 0)
    }
    
    @Test("exportSummary returns non-empty string")
    func exportSummaryNonEmpty() {
        engine.reset()
        engine.recordEvent(.impression, unit: .banner)
        let summary = engine.exportSummary()
        #expect(!summary.isEmpty)
        #expect(summary.contains("Ad Analytics Summary"))
    }
    
    @Test("EventType enum has all expected cases")
    func eventTypeEnum() {
        #expect(AdAnalyticsEngine.EventType.impression.rawValue == "impression")
        #expect(AdAnalyticsEngine.EventType.click.rawValue == "click")
        #expect(AdAnalyticsEngine.EventType.reward.rawValue == "reward")
        #expect(AdAnalyticsEngine.EventType.error.rawValue == "error")
        #expect(AdAnalyticsEngine.EventType.loaded.rawValue == "loaded")
        #expect(AdAnalyticsEngine.EventType.failed.rawValue == "failed")
        #expect(AdAnalyticsEngine.EventType.dismissed.rawValue == "dismissed")
        #expect(AdAnalyticsEngine.EventType.skipped.rawValue == "skipped")
    }
}
