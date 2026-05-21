import Testing
@testable import ForeWiz

@MainActor
struct AdRevenueTrackerTests {
    var tracker = AdRevenueTracker.shared
    
    @Test("Initial state has zero counters")
    func initialState() {
        tracker.reset()
        #expect(tracker.totalEstimatedRevenue == 0)
        #expect(tracker.eCPM == 0)
    }
    
    @Test("recordImpression increments impression count for unit")
    func recordImpressionIncrements() {
        tracker.reset()
        tracker.recordImpression(unit: .banner)
        tracker.recordImpression(unit: .banner)
        
        let stats = tracker.stats(for: .banner)
        #expect(stats.impressions == 2)
    }
    
    @Test("recordClick increments click count for unit")
    func recordClickIncrements() {
        tracker.reset()
        tracker.recordClick(unit: .native)
        
        let stats = tracker.stats(for: .native)
        #expect(stats.clicks == 1)
    }
    
    @Test("recordEstimatedRevenue accumulates revenue")
    func recordEstimatedRevenueAccumulates() {
        tracker.reset()
        tracker.recordEstimatedRevenue(unit: .interstitial, revenue: 0.05)
        tracker.recordEstimatedRevenue(unit: .interstitial, revenue: 0.03)
        
        let stats = tracker.stats(for: .interstitial)
        #expect(stats.revenue == 0.08)
    }
    
    @Test("totalEstimatedRevenue sums across all units")
    func totalEstimatedRevenueSums() {
        tracker.reset()
        tracker.recordEstimatedRevenue(unit: .banner, revenue: 0.10)
        tracker.recordEstimatedRevenue(unit: .native, revenue: 0.20)
        tracker.recordEstimatedRevenue(unit: .interstitial, revenue: 0.05)
        
        #expect(tracker.totalEstimatedRevenue == 0.35)
    }
    
    @Test("eCPM is calculated correctly")
    func eCPMCalculation() {
        tracker.reset()
        
        // 100 impressions, $0.50 total revenue
        for _ in 0..<100 {
            tracker.recordImpression(unit: .banner)
        }
        tracker.recordEstimatedRevenue(unit: .banner, revenue: 0.50)
        
        // eCPM = ($0.50 / 100) * 1000 = $5.00
        #expect(tracker.eCPM == 5.0)
    }
    
    @Test("eCPM is zero when no impressions")
    func eCPMZeroWhenNoImpressions() {
        tracker.reset()
        tracker.recordEstimatedRevenue(unit: .banner, revenue: 0.50)
        #expect(tracker.eCPM == 0)
    }
    
    @Test("stats returns zero for unit with no activity")
    func statsZeroForInactiveUnit() {
        tracker.reset()
        let stats = tracker.stats(for: .rewarded)
        #expect(stats.impressions == 0)
        #expect(stats.clicks == 0)
        #expect(stats.revenue == 0)
    }
    
    @Test("reset clears all data")
    func resetClearsData() {
        tracker.recordImpression(unit: .banner)
        tracker.recordClick(unit: .banner)
        tracker.recordEstimatedRevenue(unit: .banner, revenue: 0.10)
        
        tracker.reset()
        
        #expect(tracker.totalEstimatedRevenue == 0)
        #expect(tracker.eCPM == 0)
        
        let stats = tracker.stats(for: .banner)
        #expect(stats.impressions == 0)
        #expect(stats.clicks == 0)
        #expect(stats.revenue == 0)
    }
}
