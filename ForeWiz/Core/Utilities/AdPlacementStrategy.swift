import Foundation
import OSLog

// MARK: - Ad Placement Strategy
/// Determines when and where to show ads for optimal UX and revenue balance.
/// Uses session context, user engagement, and fatigue signals to place ads.
@MainActor
final class AdPlacementStrategy {
    static let shared = AdPlacementStrategy()
    
    // MARK: - Placement Contexts
    
    enum PlacementContext: String {
        case appLaunch = "app_launch"
        case weatherRefresh = "weather_refresh"
        case locationChange = "location_change"
        case insightView = "insight_view"
        case recommendationTap = "recommendation_tap"
        case settingsOpen = "settings_open"
        case wizpathOpen = "wizpath_open"
    }
    
    // MARK: - Configuration
    
    struct Config {
        /// Minimum time between native ad placements (seconds)
        static let minNativeInterval: TimeInterval = 300 // 5 minutes
        /// Minimum time between banner refreshes
        static let minBannerInterval: TimeInterval = 60
        /// Show app open ad every N foreground events
        static let appOpenEveryNForeground = 2
        /// Minimum session length to show interstitial (seconds)
        static let minSessionForInterstitial: TimeInterval = 120
    }
    
    // MARK: - State
    
    private var lastNativeAdTime: Date?
    private var lastBannerRefreshTime: Date?
    private var foregroundCount = 0
    private var sessionStartTime: Date?
    private var isSessionActive = false
    private var shownAdsToday: [AdManager.AdUnit: Int] = [:]
    
    private init() {}
    
    // MARK: - Session Management
    
    func sessionStarted() {
        guard !isSessionActive else { return }
        isSessionActive = true
        sessionStartTime = Date()
        foregroundCount += 1
        AppLogger.app.info("[AdPlacement] Session started (foreground #\(self.foregroundCount))")
    }
    
    func sessionEnded() {
        isSessionActive = false
        sessionStartTime = nil
        AppLogger.app.info("[AdPlacement] Session ended")
    }
    
    // MARK: - Placement Decisions
    
    /// Should show app open ad on this foreground event?
    func shouldShowAppOpen() -> Bool {
        guard foregroundCount >= Config.appOpenEveryNForeground else { return false }
        guard AdManager.shared.canShow(.appOpen) else { return false }
        return true
    }
    
    /// Should show a native ad in the given context?
    func shouldShowNative(at context: PlacementContext) -> Bool {
        guard AdManager.shared.canShow(.native) else { return false }
        
        // Check cooldown
        if let lastTime = lastNativeAdTime {
            guard Date().timeIntervalSince(lastTime) >= Config.minNativeInterval else { return false }
        }
        
        return true
    }
    
    /// Should show an interstitial ad at a natural transition point?
    func shouldShowInterstitial(at context: PlacementContext) -> Bool {
        guard AdManager.shared.canShow(.interstitial) else { return false }
        
        // Only show if user has been in session for a while
        if let sessionStart = sessionStartTime {
            guard Date().timeIntervalSince(sessionStart) >= Config.minSessionForInterstitial else { return false }
        }
        
        return true
    }
    
    /// Should show a banner ad in the current context?
    func shouldShowBanner() -> Bool {
        return AdManager.shared.canShow(.banner)
    }
    
    // MARK: - Recording
    
    /// Record that an ad was shown (updates placement strategy state)
    func recordAdShown(_ unit: AdManager.AdUnit) {
        shownAdsToday[unit, default: 0] += 1
        
        switch unit {
        case .native:
            lastNativeAdTime = Date()
        case .banner:
            lastBannerRefreshTime = Date()
        default:
            break
        }
    }
    
    // MARK: - Debug
    
    func debugInfo() -> String {
        var info = "=== Ad Placement Strategy ===\n"
        info += "Session Active: \(isSessionActive)\n"
        info += "Foreground Count: \(foregroundCount)\n"
        info += "Shown Today:\n"
        for (unit, count) in shownAdsToday {
            info += "  \(unit.rawValue): \(count)\n"
        }
        return info
    }
    
    func reset() {
        lastNativeAdTime = nil
        lastBannerRefreshTime = nil
        foregroundCount = 0
        sessionStartTime = nil
        isSessionActive = false
        shownAdsToday.removeAll()
    }
}
