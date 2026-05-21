import Foundation
import Testing
@testable import ForeWiz

@MainActor
struct AdFatiguePreventionTests {
    let fatigue = AdFatiguePrevention.shared
    
    @Test("Initial fatigue level is healthy")
    func initialLevelHealthy() {
        fatigue.reset()
        #expect(fatigue.currentLevel() == .healthy)
    }
    
    @Test("shouldShowAd returns true when healthy")
    func shouldShowAdWhenHealthy() {
        fatigue.reset()
        #expect(fatigue.shouldShowAd())
    }
    
    @Test("adjustedInterval returns base interval when healthy")
    func adjustedIntervalHealthy() {
        fatigue.reset()
        let base: TimeInterval = 60
        #expect(fatigue.adjustedInterval(baseInterval: base) == base)
    }
    
    @Test("adjustedDailyLimit returns base limit when healthy")
    func adjustedDailyLimitHealthy() {
        fatigue.reset()
        let base = 10
        #expect(fatigue.adjustedDailyLimit(baseLimit: base) == base)
    }
    
    @Test("recordImpression updates state without crash")
    func recordImpressionUpdatesState() {
        fatigue.reset()
        fatigue.recordImpression()
        #expect(fatigue.currentLevel() == .healthy) // Still healthy with 1 impression
    }
    
    @Test("multiple impressions trigger mild fatigue at threshold")
    func mildFatigueAtThreshold() {
        fatigue.reset()
        // Trigger mild at 15 impressions
        for _ in 0..<15 {
            fatigue.recordImpression()
        }
        let level = fatigue.currentLevel()
        #expect(level == .mild)
    }
    
    @Test("recordClick updates state without crash")
    func recordClick() {
        fatigue.reset()
        fatigue.recordClick()
    }
    
    @Test("recordDismiss updates state without crash")
    func recordDismiss() {
        fatigue.reset()
        fatigue.recordDismiss()
    }
    
    @Test("reset clears all state")
    func resetClearsState() {
        for _ in 0..<20 {
            fatigue.recordImpression()
        }
        fatigue.reset()
        #expect(fatigue.currentLevel() == .healthy)
        #expect(fatigue.shouldShowAd())
    }
    
    @Test("FatigueLevel multiplier values are valid")
    func fatigueLevelMultipliers() {
        #expect(AdFatiguePrevention.FatigueLevel.healthy.multiplier == 1.0)
        #expect(AdFatiguePrevention.FatigueLevel.mild.multiplier == 0.75)
        #expect(AdFatiguePrevention.FatigueLevel.moderate.multiplier == 0.5)
        #expect(AdFatiguePrevention.FatigueLevel.severe.multiplier == 0.25)
        #expect(AdFatiguePrevention.FatigueLevel.critical.multiplier == 0.0)
    }
    
    @Test("FatigueLevel cooldown multipliers are >= 1.0")
    func fatigueLevelCooldownMultipliers() {
        #expect(AdFatiguePrevention.FatigueLevel.healthy.cooldownMultiplier == 1.0)
        #expect(AdFatiguePrevention.FatigueLevel.mild.cooldownMultiplier == 1.5)
        #expect(AdFatiguePrevention.FatigueLevel.moderate.cooldownMultiplier == 2.0)
        #expect(AdFatiguePrevention.FatigueLevel.severe.cooldownMultiplier == 3.0)
        #expect(AdFatiguePrevention.FatigueLevel.critical.cooldownMultiplier == 10.0)
    }
    
    @Test("critical fatigue prevents ad showing")
    func criticalFatigueBlocksAds() {
        fatigue.reset()
        // Trigger critical at 45 impressions
        for _ in 0..<45 {
            fatigue.recordImpression()
        }
        #expect(!fatigue.shouldShowAd())
    }
}
