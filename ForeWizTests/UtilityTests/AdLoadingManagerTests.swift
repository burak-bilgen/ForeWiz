import Testing
@testable import ForeWiz

@MainActor
struct AdLoadingManagerTests {
    let manager = AdLoadingManager.shared
    
    @Test("Initial state is idle for all units")
    func initialStateIdle() {
        manager.clearAllCaches()
        for unit in AdManager.AdUnit.allCases {
            let state = manager.state(for: unit)
            if case .idle = state {
                #expect(true)
            } else {
                #expect(false, "Expected idle for \(unit.rawValue)")
            }
        }
    }
    
    @Test("markLoading sets loading state")
    func markLoadingSetsLoading() {
        manager.clearAllCaches()
        manager.markLoading(.banner)
        
        let state = manager.state(for: .banner)
        if case .loading = state {
            #expect(true)
        } else {
            #expect(false, "Expected loading state")
        }
    }
    
    @Test("markLoaded sets loaded state")
    func markLoadedSetsLoaded() {
        manager.clearAllCaches()
        manager.markLoaded(.native)
        
        #expect(manager.isReady(.native))
        #expect(manager.state(for: .native).isLoaded)
    }
    
    @Test("markFailed sets failed state")
    func markFailedSetsFailed() {
        manager.clearAllCaches()
        manager.markFailed(.interstitial)
        
        let state = manager.state(for: .interstitial)
        if case .failed = state {
            #expect(true)
        } else {
            #expect(false, "Expected failed state")
        }
    }
    
    @Test("clearCache resets unit to idle")
    func clearCacheResetsUnit() {
        manager.markLoaded(.banner)
        manager.clearCache(.banner)
        
        let state = manager.state(for: .banner)
        if case .idle = state {
            #expect(true)
        } else {
            #expect(false, "Expected idle after clear")
        }
    }
    
    @Test("clearAllCaches resets all units")
    func clearAllCachesResetsAll() {
        manager.markLoaded(.banner)
        manager.markLoaded(.native)
        manager.markLoaded(.interstitial)
        
        manager.clearAllCaches()
        
        for unit in AdManager.AdUnit.allCases {
            let state = manager.state(for: unit)
            if case .idle = state {
                #expect(true)
            } else {
                #expect(false, "Expected idle for \(unit.rawValue)")
            }
        }
    }
    
    @Test("isReady returns false for non-loaded states")
    func isReadyFalseForNonLoaded() {
        manager.clearAllCaches()
        #expect(!manager.isReady(.banner))
        #expect(!manager.isReady(.native))
        #expect(!manager.isReady(.interstitial))
    }
    
    @Test("debugInfo returns non-empty string")
    func debugInfoNonEmpty() {
        manager.clearAllCaches()
        manager.markLoaded(.banner)
        let info = manager.debugInfo()
        #expect(!info.isEmpty)
        #expect(info.contains("Ad Loading Manager"))
    }
    
    @Test("LoadState enum isEquatable works")
    func loadStateEquatable() {
        let idle1 = AdLoadingManager.LoadState.idle
        let idle2 = AdLoadingManager.LoadState.idle
        #expect(idle1.isLoading == idle2.isLoading)
        #expect(idle1.isLoaded == idle2.isLoaded)
    }
}
