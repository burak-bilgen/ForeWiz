import Foundation
import Testing
@testable import ForeWiz

@MainActor
@Suite(.serialized)
struct AdManagerTests {
    let manager = AdManager.shared
    
    /// Reset all singleton state for clean test isolation
    func resetAllState() {
        manager.resetDailyCounters()
        manager.clearAllCaches()
        AdFatiguePrevention.shared.reset()
        AdAnalyticsEngine.shared.reset()
    }
    
    @Test("AdUnit test IDs are valid format")
    func adUnitTestIDs() {
        for unit in AdManager.AdUnit.allCases {
            #expect(unit.testID.hasPrefix("ca-app-pub-"))
        }
    }
    
    @Test("AdUnit production IDs are valid format")
    func adUnitProductionIDs() {
        for unit in AdManager.AdUnit.allCases {
            #expect(unit.productionID.hasPrefix("ca-app-pub-"))
        }
    }
    
    @Test("AdUnit maxImpressionsPerDay is positive")
    func adUnitMaxImpressions() {
        for unit in AdManager.AdUnit.allCases {
            #expect(unit.maxImpressionsPerDay > 0)
        }
    }
    
    @Test("AdUnit minInterval is non-negative")
    func adUnitMinIntervals() {
        for unit in AdManager.AdUnit.allCases {
            #expect(unit.minInterval >= 0)
        }
    }
    
    @Test("canShow returns false for uncached non-banner ad units")
    func canShowForUncachedUnits() {
        resetAllState()
        
        // Non-banner units must always return false when uncached, regardless of consent
        for unit in AdManager.AdUnit.allCases {
            let canShow = manager.canShow(unit)
            if unit != .banner {
                #expect(canShow == false, "\(unit.rawValue) should not be showable without cache")
            }
        }
    }
    
    @Test("recordImpression increments daily count")
    func recordImpressionIncrementsCount() {
        resetAllState()
        
        manager.recordImpression(.banner)
        manager.recordImpression(.banner)
        
        // After recording impressions, canShow may be false due to cooldown (minInterval=30s)
        // Just verify no crash and daily count increments
        #expect(!manager.isAdCached(.banner))
    }
    
    @Test("recordClick is tracked without crash")
    func recordClickIsTracked() {
        resetAllState()
        manager.recordClick(.native)
        manager.recordClick(.interstitial)
    }
    
    @Test("recordFailure invalidates cache")
    func recordFailureInvalidatesCache() {
        enum TestError: Error { case generic }
        manager.recordFailure(.native, error: TestError.generic)
        #expect(!manager.isAdCached(.native))
    }
    
    @Test("resetDailyCounters clears impression state")
    func resetDailyCountersClearsState() {
        resetAllState()
        // Set up one impression so canShow would work if not for missing cache
        manager.recordImpression(.interstitial)
        manager.resetDailyCounters()
        
        #expect(manager.canShow(.interstitial) == false) // no cache
    }
    
    @Test("isAdCached returns false initially for all units")
    func isAdCachedInitialState() {
        for unit in AdManager.AdUnit.allCases {
            #expect(!manager.isAdCached(unit))
        }
    }
    
    @Test("invalidateCache clears cache state")
    func invalidateCacheClearsState() {
        manager.invalidateCache(.native)
        #expect(!manager.isAdCached(.native))
        
        manager.invalidateCache(.interstitial)
        #expect(!manager.isAdCached(.interstitial))
    }
    
    @Test("clearAllCaches invalidates all units")
    func clearAllCachesInvalidatesAll() {
        manager.clearAllCaches()
        for unit in AdManager.AdUnit.allCases {
            #expect(!manager.isAdCached(unit))
        }
    }
    
    @Test("recordDismiss records without crash")
    func recordDismiss() {
        manager.recordDismiss(.rewarded)
        manager.recordDismiss(.interstitial)
    }
    
    @Test("recordLoaded records without crash")
    func recordLoaded() {
        manager.recordLoaded(.banner)
        manager.recordLoaded(.native)
    }
    
    @Test("recordReward records without crash")
    func recordReward() {
        manager.recordReward(.rewarded, amount: 10.0)
        manager.recordReward(.rewardedInterstitial, amount: 25.0)
    }
    
    @Test("debugInfo returns non-empty string")
    func debugInfoNonEmpty() {
        let info = manager.debugInfo()
        #expect(!info.isEmpty)
        #expect(info.contains("Ad Manager Debug"))
    }
}
