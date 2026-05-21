import Foundation
import OSLog

// MARK: - Ad Placement Strategy
/// Intelligent ad placement system that determines optimal moments
/// to show ads based on user behavior, session context, and natural
/// transition points.
///
/// Follows Google AdMob best practices:
/// - Show ads at natural breaks (not during active tasks)
/// - Respect user flow and engagement patterns
/// - Avoid ad fatigue with smart frequency distribution
@MainActor
final class AdPlacementStrategy {
    static let shared = AdPlacementStrategy()
    
    // MARK: - Placement Points
    
    enum PlacementPoint: String {
        /// After app launch and initial load
        case appLaunch
        /// After user refreshes weather data
        case weatherRefresh
        /// After viewing detailed recommendation
        case recommendationViewed
        /// After checking WizPath route
        case wizPathComplete
        /// After changing location
        case locationChanged
        /// After viewing insights
        case insightsViewed
        /// After completing onboarding
        case onboardingComplete
        /// Natural break between scrolling sessions
        case scrollBreak
    }
    
    // MARK: - Configuration
    
    struct Config {
        /// Minimum session duration before showing interstitial (seconds)
        static let minSessionDurationForInterstitial: TimeInterval = 60
        
        /// Maximum interstitials per session
        static let maxInterstitialsPerSession = 3
        
        /// Show interstitial after this many placement points
        static let interstitialTriggerPoints = 4
        
        /// Show banner after this many seconds on screen
        static let bannerShowDelay: TimeInterval = 2.0
        
        /// Don't show ads during first N seconds of app usage
        static let gracePeriod: TimeInterval = 10
    }
    
    // MARK: - State
    
    private var sessionStartTime: Date?
    private var placementPointCount = 0
    private var interstitialsThisSession = 0
    private var lastInterstitialTime: Date?
    private var hasShownLaunchAd = false
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Session Management
    
    /// Call when user opens app or returns from background
    func sessionStarted() {
        sessionStartTime = Date()
        placementPointCount = 0
        interstitialsThisSession = 0
        hasShownLaunchAd = false
        
        AppLogger.app.info("[AdPlacement] Session started")
    }
    
    /// Call when user sends app to background
    func sessionEnded() {
        sessionStartTime = nil
        placementPointCount = 0
        interstitialsThisSession = 0
        
        AppLogger.app.info("[AdPlacement] Session ended")
    }
    
    // MARK: - Placement Decisions
    
    /// Check if a banner ad should be shown at this placement point
    func shouldShowBanner(at point: PlacementPoint) -> Bool {
        guard isGracePeriodOver() else { return false }
        guard AdManager.shared.canShow(.banner) else { return false }
        
        // Don't show banner immediately on launch
        if point == .appLaunch {
            return false
        }
        
        return true
    }
    
    /// Check if a native ad should be shown at this placement point
    func shouldShowNative(at point: PlacementPoint) -> Bool {
        guard isGracePeriodOver() else { return false }
        guard AdManager.shared.canShow(.native) else { return false }
        
        // Native ads work well after content consumption
        switch point {
        case .recommendationViewed, .wizPathComplete, .insightsViewed:
            return true
        default:
            return false
        }
    }
    
    /// Check if an interstitial ad should be shown at this placement point
    func shouldShowInterstitial(at point: PlacementPoint) -> Bool {
        guard isGracePeriodOver() else { return false }
        guard AdManager.shared.canShow(.interstitial) else { return false }
        
        // Check session duration
        if let sessionStart = sessionStartTime {
            let sessionDuration = Date().timeIntervalSince(sessionStart)
            guard sessionDuration >= Config.minSessionDurationForInterstitial else {
                return false
            }
        }
        
        // Check session limit
        guard interstitialsThisSession < Config.maxInterstitialsPerSession else {
            return false
        }
        
        // Check cooldown
        if let lastTime = lastInterstitialTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            guard elapsed >= AdManager.AdUnit.interstitial.minInterval else {
                return false
            }
        }
        
        // Check if we've hit enough placement points
        placementPointCount += 1
        guard placementPointCount >= Config.interstitialTriggerPoints else {
            return false
        }
        
        // Reset counter after showing
        placementPointCount = 0
        
        return true
    }
    
    /// Check if an app open ad should be shown
    func shouldShowAppOpen() -> Bool {
        guard !hasShownLaunchAd else { return false }
        guard AdManager.shared.canShow(.appOpen) else { return false }
        guard isGracePeriodOver() else { return false }
        
        hasShownLaunchAd = true
        return true
    }
    
    // MARK: - Recording
    
    /// Record that an ad was shown
    func recordAdShown(_ unit: AdManager.AdUnit) {
        switch unit {
        case .interstitial:
            interstitialsThisSession += 1
            lastInterstitialTime = Date()
        case .appOpen:
            hasShownLaunchAd = true
        default:
            break
        }
        
        AppLogger.app.info("[AdPlacement] Ad shown: \(unit.rawValue) (session interstitials: \(self.interstitialsThisSession))")
    }
    
    // MARK: - Helpers
    
    private func isGracePeriodOver() -> Bool {
        guard let sessionStart = sessionStartTime else { return false }
        return Date().timeIntervalSince(sessionStart) >= Config.gracePeriod
    }
    
    // MARK: - Debug
    
    func debugInfo() -> String {
        """
        === Ad Placement Debug ===
        Session Active: \(sessionStartTime != nil)
        Placement Points: \(placementPointCount)/\(Config.interstitialTriggerPoints)
        Interstitials This Session: \(interstitialsThisSession)/\(Config.maxInterstitialsPerSession)
        Grace Period Over: \(isGracePeriodOver())
        """
    }
}
