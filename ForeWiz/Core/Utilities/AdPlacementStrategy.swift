import Foundation
import OSLog

// MARK: - Ad Placement Strategy
/// Determines when and where to show ads for optimal UX and revenue balance.
/// Uses session context, user engagement, and fatigue signals to place ads.
/// Features randomized placement positions so ads don't always appear in the same spot.
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
    
    // MARK: - Insertion Points (for home screen content)
    
    /// Possible positions where an ad can appear in the home scroll view
    enum InsertionPoint: CaseIterable {
        /// After hero/current conditions card
        case afterHero
        /// After hourly forecast
        case afterHourly
        /// After weekly forecast (default position)
        case afterWeekly
        /// Before footer
        case beforeFooter
        
        /// Weighted probability for random selection (higher = more likely)
        var weight: Int {
            switch self {
            case .afterHero: return 1    // Rare — too early, interrupts context
            case .afterHourly: return 2
            case .afterWeekly: return 4  // Most common — after content consumption
            case .beforeFooter: return 2
            }
        }
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
        /// Probability of showing an ad on any given home load (0.0–1.0)
        static let homeAdProbability: Double = 0.55
        /// Probability of showing a second ad on the same view (0.0–1.0) — kept low to avoid overload
        static let secondAdProbability: Double = 0.15
    }
    
    // MARK: - State
    
    private var lastNativeAdTime: Date?
    private var lastBannerRefreshTime: Date?
    private var foregroundCount = 0
    private var sessionStartTime: Date?
    private var isSessionActive = false
    private var shownAdsToday: [AdManager.AdUnit: Int] = [:]
    private var lastInsertionPoints: [InsertionPoint] = []  // Avoid repeating the same position
    private var viewLoadCount = 0
    
    private init() {}
    
    // MARK: - Session Management
    
    func sessionStarted() {
        guard !isSessionActive else { return }
        isSessionActive = true
        sessionStartTime = Date()
        foregroundCount += 1
        viewLoadCount = 0
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
    
    // MARK: - Randomized Home Screen Placement
    
    /// Decide whether to show ads on the home screen for this load,
    /// and if so, which insertion points to use (weighted random).
    /// Returns an array of InsertionPoints — empty means no ads this time.
    /// At most 2 points are returned, and they each show only ONE format
    /// (native OR banner, never both at the same point) to avoid overload.
    func decideHomePlacement() -> [InsertionPoint] {
        viewLoadCount += 1
        
        // Fatigue check
        guard AdFatiguePrevention.shared.shouldShowAd() else { return [] }
        
        // Probabilistic skip — lower probability on first load, higher on subsequent
        let probability = viewLoadCount <= 1 ? Config.homeAdProbability * 0.7 : Config.homeAdProbability
        guard Double.random(in: 0...1) < probability else { return [] }
        
        // Decide how many insertion points: 1 or 2 (second one is rare)
        let count = Double.random(in: 0...1) < Config.secondAdProbability ? 2 : 1
        
        // Weighted random selection of insertion points, avoiding recent positions
        let allPoints = InsertionPoint.allCases
        let weighted = allPoints.flatMap { point -> [InsertionPoint] in
            // Reduce weight for recently used positions
            let recencyPenalty = lastInsertionPoints.contains(point) ? 2 : 0
            let effectiveWeight = max(1, point.weight - recencyPenalty)
            return Array(repeating: point, count: effectiveWeight)
        }
        
        guard !weighted.isEmpty else { return [.afterWeekly] }
        
        var selected: [InsertionPoint] = []
        var available = weighted
        
        for _ in 0..<min(count, weighted.count) {
            guard let pick = available.randomElement() else { break }
            selected.append(pick)
            available.removeAll { $0 == pick }
        }
        
        // Cache selected points to avoid repeating same positions
        lastInsertionPoints = selected
        
        AppLogger.app.info("[AdPlacement] Home placement: \(selected.map(\.rawName).joined(separator: ", "))")
        return selected.sorted { $0.order < $1.order }
    }
    
    /// Returns true if there's room in the daily budget to show an ad right now
    func canShowInlineAd() -> Bool {
        AdManager.shared.canShow(.native) || AdManager.shared.canShow(.banner)
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
        info += "View Load Count: \(viewLoadCount)\n"
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
        lastInsertionPoints.removeAll()
        viewLoadCount = 0
    }
}

// MARK: - InsertionPoint Helpers

private extension AdPlacementStrategy.InsertionPoint {
    var order: Int {
        switch self {            case .afterHero: return 0
            case .afterHourly: return 1
        case .afterWeekly: return 3
        case .beforeFooter: return 4
        }
    }
    
    var rawName: String {
        switch self {
        case .afterHero: return "afterHero"
        case .afterHourly: return "afterHourly"
        case .afterWeekly: return "afterWeekly"
        case .beforeFooter: return "beforeFooter"
        }
    }
}
