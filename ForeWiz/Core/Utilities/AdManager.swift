import Foundation
import OSLog

// MARK: - Ad Manager
/// Centralized ad management system with intelligent loading, caching, and frequency control.
/// Supports banner, native, and interstitial ad formats with weather-aware placement.
@MainActor
final class AdManager {
    static let shared = AdManager()
    
    // MARK: - Configuration
    
    struct Config {
        static let testMode = true
        static let maxImpressionsPerDay = 50
        static let minIntervalBetweenInterstitials: TimeInterval = 120
        static let bannerRefreshInterval: TimeInterval = 60
    }
    
    // MARK: - State
    
    private(set) var isInitialized = false
    private(set) var dailyImpressionCount = 0
    private(set) var lastInterstitialTime: Date?
    private var bannerLoadTime: Date?
    
    // MARK: - Ad Units
    
    enum AdUnitID: String {
        case homeBanner = "forewiz_home_banner"
        case insightsBanner = "forewiz_insights_banner"
        case nativeCard = "forewiz_native_card"
        case interstitialMain = "forewiz_interstitial_main"
        
        var testID: String {
            switch self {
            case .homeBanner: return "test_banner_001"
            case .insightsBanner: return "test_banner_002"
            case .nativeCard: return "test_native_001"
            case .interstitialMain: return "test_interstitial_001"
            }
        }
        
        var productionID: String {
            switch self {
            case .homeBanner: return "forewiz_home_banner_prod"
            case .insightsBanner: return "forewiz_insights_banner_prod"
            case .nativeCard: return "forewiz_native_card_prod"
            case .interstitialMain: return "forewiz_interstitial_main_prod"
            }
        }
        
        var currentID: String {
            Config.testMode ? testID : productionID
        }
    }
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Initialization
    
    func initialize() async {
        guard !isInitialized else { return }
        
        AppLogger.app.info("AdManager initializing...")
        
        #if DEBUG
        AppLogger.app.info("AdManager running in TEST MODE")
        #endif
        
        isInitialized = true
        dailyImpressionCount = 0
        lastInterstitialTime = nil
        
        AppLogger.app.info("AdManager initialized successfully")
    }
    
    // MARK: - Impression Tracking
    
    func trackImpression(for unit: AdUnitID) {
        dailyImpressionCount += 1
        
        if self.dailyImpressionCount >= Config.maxImpressionsPerDay {
            AppLogger.app.warning("Daily impression limit reached: \(Config.maxImpressionsPerDay)")
        }
        
        AppLogger.analytics.info("Ad impression: \(unit.rawValue) (daily: \(self.dailyImpressionCount))")
    }
    
    func trackClick(for unit: AdUnitID) {
        AppLogger.analytics.info("Ad click: \(unit.rawValue)")
    }
    
    // MARK: - Frequency Control
    
    func canShowInterstitial() -> Bool {
        guard dailyImpressionCount < Config.maxImpressionsPerDay else { return false }
        
        if let lastTime = lastInterstitialTime {
            return Date().timeIntervalSince(lastTime) >= Config.minIntervalBetweenInterstitials
        }
        
        return true
    }
    
    func recordInterstitialShown() {
        lastInterstitialTime = Date()
        trackImpression(for: .interstitialMain)
    }
    
    func canShowBanner() -> Bool {
        dailyImpressionCount < Config.maxImpressionsPerDay
    }
    
    func shouldRefreshBanner() -> Bool {
        guard let lastLoad = bannerLoadTime else { return true }
        return Date().timeIntervalSince(lastLoad) >= Config.bannerRefreshInterval
    }
    
    func recordBannerShown() {
        bannerLoadTime = Date()
        trackImpression(for: .homeBanner)
    }
    
    // MARK: - Reset
    
    func resetDailyCount() {
        dailyImpressionCount = 0
        lastInterstitialTime = nil
        AppLogger.app.info("AdManager daily count reset")
    }
}
