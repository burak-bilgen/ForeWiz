import Foundation
import OSLog

// MARK: - Ad Manager
/// Production-grade ad management system with intelligent preloading, caching,
/// frequency control, and lifecycle management.
///
/// Architecture follows Google AdMob best practices:
/// - Preload ads before showing (zero latency display)
/// - Cache management with 1-hour expiry
/// - Smart frequency capping to protect UX
/// - Natural transition point placement
/// - Full lifecycle tracking for analytics
@MainActor
final class AdManager {
    static let shared = AdManager()
    
    // MARK: - Configuration
    
    struct Config {
        /// Test mode - uses Google test ad unit IDs
        #if DEBUG
        static let testMode = true
        #else
        static let testMode = false
        #endif
        
        /// Maximum impressions per day per format
        static let maxBannerImpressionsPerDay = 100
        static let maxNativeImpressionsPerDay = 30
        static let maxInterstitialImpressionsPerDay = 8
        static let maxAppOpenImpressionsPerDay = 20
        
        /// Minimum interval between same-format impressions
        static let minBannerInterval: TimeInterval = 30
        static let minNativeInterval: TimeInterval = 60
        static let minInterstitialInterval: TimeInterval = 180
        static let minAppOpenInterval: TimeInterval = 300
        
        /// Ad cache expiry (Google recommends 1 hour)
        static let cacheExpiryInterval: TimeInterval = 3600
        
        /// Preload triggers
        static let preloadOnLaunch = true
        static let preloadInterstitialAfterShows = 1
    }
    
    // MARK: - Ad Unit IDs
    
    enum AdUnit: String, CaseIterable {
        case banner = "banner"
        case native = "native"
        case interstitial = "interstitial"
        case appOpen = "app_open"
        case rewarded = "rewarded"
        case rewardedInterstitial = "rewarded_interstitial"
        
        /// Google test ad unit IDs (safe for development)
        var testID: String {
            switch self {
            case .banner: return "ca-app-pub-3940256099942544/2435281174"
            case .native: return "ca-app-pub-3940256099942544/3986624511"
            case .interstitial: return "ca-app-pub-3940256099942544/4411468910"
            case .appOpen: return "ca-app-pub-3940256099942544/5662855259"
            case .rewarded: return "ca-app-pub-3940256099942544/1712485313"
            case .rewardedInterstitial: return "ca-app-pub-3940256099942544/5354046376"
            }
        }
        
        /// Production ad unit IDs (set these in AdMob dashboard)
        var productionID: String {
            switch self {
            case .banner: return "ca-app-pub-3149735625847287/1558365536"
            case .native: return "ca-app-pub-3149735625847287/7796470827"
            case .interstitial: return "ca-app-pub-3149735625847287/4268289356"
            case .appOpen: return "ca-app-pub-3149735625847287/2544144142"
            case .rewarded: return "ca-app-pub-3149735625847287/7136023057"
            case .rewardedInterstitial: return "ca-app-pub-3149735625847287/2214868860"
            }
        }
        
        var currentID: String {
            Config.testMode ? testID : productionID
        }
        
        var maxImpressionsPerDay: Int {
            switch self {
            case .banner: return Config.maxBannerImpressionsPerDay
            case .native: return Config.maxNativeImpressionsPerDay
            case .interstitial: return Config.maxInterstitialImpressionsPerDay
            case .appOpen: return Config.maxAppOpenImpressionsPerDay
            case .rewarded: return 10
            case .rewardedInterstitial: return 5
            }
        }
        
        var minInterval: TimeInterval {
            switch self {
            case .banner: return Config.minBannerInterval
            case .native: return Config.minNativeInterval
            case .interstitial: return Config.minInterstitialInterval
            case .appOpen: return Config.minAppOpenInterval
            case .rewarded: return 120
            case .rewardedInterstitial: return 180
            }
        }
    }
    
    // MARK: - State
    
    private(set) var isInitialized = false
    private(set) var isLoading = false
    
    /// Daily impression counters per ad unit
    private var dailyImpressions: [AdUnit: Int] = [:]
    private var dailyClicks: [AdUnit: Int] = [:]
    private var lastImpressionTime: [AdUnit: Date?] = [:]
    private var lastCacheTime: [AdUnit: Date?] = [:]
    
    /// Ad cache status
    private var isBannerCached = false
    private var isNativeCached = false
    private var isInterstitialCached = false
    private var isAppOpenCached = false
    
    /// Event callbacks
    var onBannerLoaded: (() -> Void)?
    var onBannerFailed: ((Error) -> Void)?
    var onNativeLoaded: (() -> Void)?
    var onNativeFailed: ((Error) -> Void)?
    var onInterstitialLoaded: (() -> Void)?
    var onInterstitialFailed: ((Error) -> Void)?
    var onInterstitialShown: (() -> Void)?
    var onInterstitialDismissed: (() -> Void)?
    var onAppOpenLoaded: (() -> Void)?
    var onAppOpenFailed: ((Error) -> Void)?
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Initialization
    
    /// Initialize the ad system. Call early in app lifecycle.
    func initialize() async {
        guard !isInitialized else { return }
        
        AppLogger.app.info("[Ads] Initializing...")
        isLoading = true
        
        // Reset daily counters
        resetDailyCounters()
        
        // Schedule daily reset at midnight
        scheduleDailyReset()
        
        // Reset fatigue tracking
        AdFatiguePrevention.shared.reset()
        
        // Start new analytics session
        AdAnalyticsEngine.shared.startNewSession()
        
        #if DEBUG
        AppLogger.app.info("[Ads] Running in TEST MODE with test ad unit IDs")
        #endif
        
        // Preload ads on launch
        if Config.preloadOnLaunch {
            await preloadAllAds()
        }
        
        isInitialized = true
        isLoading = false
        
        AppLogger.app.info("[Ads] Initialized successfully")
    }
    
    // MARK: - Preloading
    
    /// Preload all ad formats for zero-latency display
    func preloadAllAds() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.preloadBanner() }
            group.addTask { await self.preloadNative() }
            group.addTask { await self.preloadInterstitial() }
            group.addTask { await self.preloadAppOpen() }
        }
    }
    
    func preloadBanner() async {
        guard canLoad(.banner) else { return }
        
        AppLogger.app.info("[Ads] Preloading banner...")
        
        // Delegate to AdMobIntegration for actual SDK loading
        let adUnitID = AdUnit.banner.currentID
        await withCheckedContinuation { continuation in
            AdMobIntegration.shared.loadBannerAd(adUnitID: adUnitID) {
                Task { @MainActor in
                    self.isBannerCached = true
                    self.lastCacheTime[.banner] = Date()
                    self.onBannerLoaded?()
                    AppLogger.app.info("[Ads] Banner preloaded")
                    continuation.resume()
                }
            } onFailure: {
                Task { @MainActor in
                    AppLogger.app.warning("[Ads] Banner preload failed")
                    continuation.resume()
                }
            }
        }
    }
    
    func preloadNative() async {
        guard canLoad(.native) else { return }
        
        AppLogger.app.info("[Ads] Preloading native ad...")
        
        let adUnitID = AdUnit.native.currentID
        await withCheckedContinuation { continuation in
            AdMobIntegration.shared.loadNativeAd(adUnitID: adUnitID) { nativeAd in
                Task { @MainActor in
                    if nativeAd != nil {
                        self.isNativeCached = true
                        self.lastCacheTime[.native] = Date()
                        self.onNativeLoaded?()
                        AppLogger.app.info("[Ads] Native ad preloaded")
                    } else {
                        AppLogger.app.warning("[Ads] Native ad preload failed")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    func preloadInterstitial() async {
        guard canLoad(.interstitial) else { return }
        
        AppLogger.app.info("[Ads] Preloading interstitial...")
        
        let adUnitID = AdUnit.interstitial.currentID
        await withCheckedContinuation { continuation in
            AdMobIntegration.shared.loadInterstitialAd(adUnitID: adUnitID) { ad in
                Task { @MainActor in
                    if ad != nil {
                        self.isInterstitialCached = true
                        self.lastCacheTime[.interstitial] = Date()
                        self.onInterstitialLoaded?()
                        AppLogger.app.info("[Ads] Interstitial preloaded")
                    } else {
                        AppLogger.app.warning("[Ads] Interstitial preload failed")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    func preloadAppOpen() async {
        guard canLoad(.appOpen) else { return }
        
        AppLogger.app.info("[Ads] Preloading app open ad...")
        
        let adUnitID = AdUnit.appOpen.currentID
        await withCheckedContinuation { continuation in
            AdMobIntegration.shared.loadAppOpenAd(adUnitID: adUnitID) { ad in
                Task { @MainActor in
                    if ad != nil {
                        self.isAppOpenCached = true
                        self.lastCacheTime[.appOpen] = Date()
                        self.onAppOpenLoaded?()
                        AppLogger.app.info("[Ads] App open ad preloaded")
                    } else {
                        AppLogger.app.warning("[Ads] App open preload failed")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Display Control
    
    /// Check if an ad can be shown (respects frequency caps and cooldowns)
    func canShow(_ unit: AdUnit) -> Bool {
        // Check fatigue prevention
        guard AdFatiguePrevention.shared.shouldShowAd() else {
            AppLogger.app.warning("[Ads] Ad blocked by fatigue prevention")
            return false
        }
        
        // Check daily limit (adjusted by fatigue)
        let impressions = dailyImpressions[unit] ?? 0
        let adjustedLimit = AdFatiguePrevention.shared.adjustedDailyLimit(baseLimit: unit.maxImpressionsPerDay)
        guard impressions < adjustedLimit else {
            AppLogger.app.warning("[Ads] Daily limit reached for \(unit.rawValue) (adjusted: \(adjustedLimit))")
            return false
        }
        
        // Check cooldown (adjusted by fatigue)
        if case .some(let lastTime) = lastImpressionTime[unit], let lastTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            let adjustedInterval = AdFatiguePrevention.shared.adjustedInterval(baseInterval: unit.minInterval)
            guard elapsed >= adjustedInterval else {
                AppLogger.app.info("[Ads] Cooldown active for \(unit.rawValue): \(Int(adjustedInterval - elapsed))s remaining")
                return false
            }
        }
        
        // Check cache (except banner which can show placeholder)
        if unit != .banner {
            guard isAdCached(unit) else {
                AppLogger.app.info("[Ads] Ad not cached for \(unit.rawValue)")
                return false
            }
        }
        
        return true
    }
    
    /// Check if an ad is cached and ready to show
    func isAdCached(_ unit: AdUnit) -> Bool {
        guard case .some(let cacheTime) = lastCacheTime[unit], let cacheTime else { return false }
        
        // Check cache expiry
        if Date().timeIntervalSince(cacheTime) > Config.cacheExpiryInterval {
            invalidateCache(unit)
            return false
        }
        
        switch unit {
        case .banner: return isBannerCached
        case .native: return isNativeCached
        case .interstitial: return isInterstitialCached
        case .appOpen: return isAppOpenCached
        case .rewarded, .rewardedInterstitial: return false
        }
    }
    
    /// Record an ad impression
    func recordImpression(_ unit: AdUnit) {
        dailyImpressions[unit, default: 0] += 1
        lastImpressionTime[unit] = Date()
        
        // Track in analytics
        AdAnalyticsEngine.shared.recordEvent(.impression, unit: unit)
        
        // Track in fatigue prevention
        AdFatiguePrevention.shared.recordImpression()
        
        AppLogger.analytics.info("[Ads] Impression: \(unit.rawValue) (daily: \(self.dailyImpressions[unit] ?? 0))")
        
        // Invalidate cache after impression (one-time use for some formats)
        if unit == .interstitial || unit == .appOpen {
            invalidateCache(unit)
            
            // Preload next ad immediately
            Task {
                if unit == .interstitial {
                    await preloadInterstitial()
                } else {
                    await preloadAppOpen()
                }
            }
        }
    }
    
    /// Record an ad click
    func recordClick(_ unit: AdUnit) {
        dailyClicks[unit, default: 0] += 1
        
        // Track in analytics
        AdAnalyticsEngine.shared.recordEvent(.click, unit: unit)
        
        // Track in fatigue prevention
        AdFatiguePrevention.shared.recordClick()
        
        AppLogger.analytics.info("[Ads] Click: \(unit.rawValue) (daily: \(self.dailyClicks[unit] ?? 0))")
    }
    
    /// Record ad load failure
    func recordFailure(_ unit: AdUnit, error: Error) {
        invalidateCache(unit)
        
        // Track in analytics
        AdAnalyticsEngine.shared.recordEvent(.failed, unit: unit, metadata: ["error": error.localizedDescription])
        
        AppLogger.app.error("[Ads] Failed to load \(unit.rawValue): \(error.localizedDescription)")
        
        switch unit {
        case .banner: onBannerFailed?(error)
        case .native: onNativeFailed?(error)
        case .interstitial: onInterstitialFailed?(error)
        case .appOpen: onAppOpenFailed?(error)
        case .rewarded, .rewardedInterstitial: break
        }
    }
    
    /// Record ad dismiss (user closed ad quickly)
    func recordDismiss(_ unit: AdUnit) {
        // Track in fatigue prevention
        AdFatiguePrevention.shared.recordDismiss()
        
        // Track in analytics
        AdAnalyticsEngine.shared.recordEvent(.dismissed, unit: unit)
        
        AppLogger.analytics.info("[Ads] Dismissed: \(unit.rawValue)")
    }
    
    /// Record ad loaded event
    func recordLoaded(_ unit: AdUnit) {
        AdAnalyticsEngine.shared.recordEvent(.loaded, unit: unit)
    }
    
    /// Record ad reward event
    func recordReward(_ unit: AdUnit, amount: Double) {
        AdAnalyticsEngine.shared.recordEvent(.reward, unit: unit, revenue: amount)
    }
    
    // MARK: - Cache Management
    
    /// Invalidate cache for a specific ad unit
    func invalidateCache(_ unit: AdUnit) {
        lastCacheTime[unit] = nil
        
        switch unit {
        case .banner: isBannerCached = false
        case .native: isNativeCached = false
        case .interstitial: isInterstitialCached = false
        case .appOpen: isAppOpenCached = false
        case .rewarded, .rewardedInterstitial: break
        }
        
        AppLogger.app.info("[Ads] Cache invalidated for \(unit.rawValue)")
    }
    
    /// Clear all caches
    func clearAllCaches() {
        for unit in AdUnit.allCases {
            invalidateCache(unit)
        }
    }
    
    /// Refresh expired caches
    func refreshExpiredCaches() async {
        for unit in AdUnit.allCases {
            if case .some(let cacheTime) = lastCacheTime[unit], let cacheTime,
               Date().timeIntervalSince(cacheTime) > Config.cacheExpiryInterval {
                invalidateCache(unit)
                
                switch unit {
                case .banner: await preloadBanner()
                case .native: await preloadNative()
                case .interstitial: await preloadInterstitial()
                case .appOpen: await preloadAppOpen()
                case .rewarded, .rewardedInterstitial: break
                }
            }
        }
    }
    
    // MARK: - Daily Reset
    
    /// Reset daily counters (call at midnight or app launch)
    func resetDailyCounters() {
        dailyImpressions.removeAll()
        dailyClicks.removeAll()
        lastImpressionTime.removeAll()
        
        AppLogger.app.info("[Ads] Daily counters reset")
    }
    
    // MARK: - Helper
    
    private func canLoad(_ unit: AdUnit) -> Bool {
        guard !isAdCached(unit) else { return false }
        return dailyImpressions[unit, default: 0] < unit.maxImpressionsPerDay
    }
    
    // MARK: - Daily Reset Scheduling
    
    /// Schedule automatic daily counter reset at midnight
    private func scheduleDailyReset() {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate next midnight
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let nextMidnight = calendar.date(bySetting: .hour, value: 0, of: tomorrow) else {
            return
        }
        
        let timeUntilMidnight = nextMidnight.timeIntervalSince(now)
        
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(timeUntilMidnight))
            await MainActor.run {
                self?.resetDailyCounters()
                self?.scheduleDailyReset() // Schedule next day's reset
            }
        }
        
        AppLogger.app.info("[Ads] Daily reset scheduled in \(Int(timeUntilMidnight / 60)) minutes")
    }
    
    // MARK: - Debug Info
    
    /// Get debug information about ad system state
    func debugInfo() -> String {
        var info = "=== Ad Manager Debug ===\n"
        info += "Initialized: \(isInitialized)\n"
        info += "Test Mode: \(Config.testMode)\n\n"
        
        for unit in AdUnit.allCases {
            info += "--- \(unit.rawValue) ---\n"
            info += "Cached: \(isAdCached(unit))\n"
            info += "Impressions today: \(self.dailyImpressions[unit] ?? 0)/\(unit.maxImpressionsPerDay)\n"
            info += "Clicks today: \(self.dailyClicks[unit] ?? 0)\n"
            if case .some(let lastTime) = lastImpressionTime[unit], let lastTime {
                let elapsed = Date().timeIntervalSince(lastTime)
                info += "Last impression: \(Int(elapsed))s ago\n"
            }
            info += "\n"
        }
        
        // Add fatigue info
        info += AdFatiguePrevention.shared.debugInfo()
        info += "\n"
        
        // Add analytics summary
        info += AdAnalyticsEngine.shared.exportSummary()
        info += "\n"
        
        // Add loading manager info
        info += AdLoadingManager.shared.debugInfo()
        
        return info
    }
}
