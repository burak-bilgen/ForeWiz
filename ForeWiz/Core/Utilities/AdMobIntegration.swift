import Foundation
import OSLog
import GoogleMobileAds

// MARK: - AdMob Integration
/// Production AdMob SDK integration with real ad loading and display.
/// Wraps Google Mobile Ads SDK with ForeWiz's ad management system.
@MainActor
final class AdMobIntegration {
    static let shared = AdMobIntegration()
    
    // MARK: - State
    
    private(set) var isSDKInitialized = false
    private(set) var currentInterstitialAd: InterstitialAd?
    private(set) var currentAppOpenAd: AppOpenAd?
    private(set) var currentNativeAds: [NativeAd] = []
    private(set) var currentBannerView: BannerView?
    private var adLoader: AdLoader?
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - SDK Initialization
    
    /// Initialize Google Mobile Ads SDK
    func initializeSDK() async {
        guard !isSDKInitialized else { return }
        
        AppLogger.app.info("[AdMob] Initializing Google Mobile Ads SDK...")
        
        await withCheckedContinuation { continuation in
            MobileAds.shared.start(completionHandler: { [weak self] _ in
                Task { @MainActor in
                    self?.isSDKInitialized = true
                    AppLogger.app.info("[AdMob] SDK initialization complete")
                    continuation.resume()
                }
            })
        }
    }
    
    // MARK: - Banner Ads
    
    /// Load a banner ad with callback (for AdManager preload)
    func loadBannerAd(
        adUnitID: String,
        onSuccess: @escaping () -> Void,
        onFailure: @escaping () -> Void
    ) {
        // Get root VC for banner loading
        guard let rootVC = rootViewController() else {
            onFailure()
            return
        }
        
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootVC
        bannerView.delegate = AdMobBannerDelegate.shared
        
        // Store banner before loading
        self.currentBannerView = bannerView
        
        AdMobBannerDelegate.shared.onLoadCompletion = { success in
            if success {
                onSuccess()
            } else {
                onFailure()
            }
        }
        
        let request = Request()
        bannerView.load(request)
        AppLogger.app.info("[AdMob] Banner ad loading...")
    }
    
    /// Create a banner view for inline display (used by AdBannerView)
    func createBannerView(
        adUnitID: String,
        rootViewController: UIViewController
    ) -> BannerView {
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootViewController
        bannerView.delegate = AdMobBannerDelegate.shared
        return bannerView
    }
    
    // MARK: - Native Ads
    
    /// Load a single native ad with callback (for AdManager preload)
    func loadNativeAd(
        adUnitID: String,
        completion: @escaping (NativeAd?) -> Void
    ) {
        guard let rootVC = rootViewController() else {
            completion(nil)
            return
        }
        
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootVC,
            adTypes: [.native],
            options: []
        )
        adLoader?.delegate = AdMobNativeLoaderDelegate.shared
        
        AdMobNativeLoaderDelegate.shared.onSingleAdLoaded = { nativeAd in
            completion(nativeAd)
        }
        AdMobNativeLoaderDelegate.shared.onLoadFailed = {
            completion(nil)
        }
        
        adLoader?.load(Request())
        AppLogger.app.info("[AdMob] Loading native ad...")
    }
    
    /// Load native ads (bulk)
    func loadNativeAds(
        adUnitID: String,
        rootViewController: UIViewController,
        completion: @escaping ([NativeAd]) -> Void
    ) {
        currentNativeAds.removeAll()
        
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: []
        )
        adLoader?.delegate = AdMobNativeLoaderDelegate.shared
        
        AdMobNativeLoaderDelegate.shared.onAdsLoaded = { [weak self] ads in
            self?.currentNativeAds = ads
            completion(ads)
        }
        
        adLoader?.load(Request())
        AppLogger.app.info("[AdMob] Loading native ads...")
    }
    
    // MARK: - Interstitial Ads
    
    /// Load an interstitial ad
    func loadInterstitialAd(
        adUnitID: String,
        completion: @escaping (InterstitialAd?) -> Void
    ) {
        InterstitialAd.load(
            with: adUnitID,
            request: Request()
        ) { [weak self] ad, error in
            if let error = error {
                AppLogger.app.error("[AdMob] Interstitial load failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            Task { @MainActor in
                self?.currentInterstitialAd = ad
                self?.currentInterstitialAd?.fullScreenContentDelegate = AdMobInterstitialDelegate.shared
                AppLogger.app.info("[AdMob] Interstitial ad loaded")
                completion(ad)
            }
        }
    }
    
    /// Show interstitial ad if available
    func showInterstitialAd(
        from viewController: UIViewController,
        onDismiss: @escaping () -> Void
    ) -> Bool {
        guard let interstitialAd = currentInterstitialAd else {
            AppLogger.app.info("[AdMob] No interstitial ad available")
            return false
        }
        
        AdMobInterstitialDelegate.shared.onAdDismissed = onDismiss
        interstitialAd.present(from: viewController)
        currentInterstitialAd = nil
        
        // Single tracking point - AdManager.recordImpression handles analytics/fatigue
        AdManager.shared.recordImpression(.interstitial)
        AdRevenueTracker.shared.recordImpression(unit: .interstitial)
        AdPlacementStrategy.shared.recordAdShown(.interstitial)
        
        AppLogger.app.info("[AdMob] Interstitial ad presented")
        return true
    }
    
    // MARK: - App Open Ads
    
    /// Load an app open ad
    func loadAppOpenAd(
        adUnitID: String,
        completion: @escaping (AppOpenAd?) -> Void
    ) {
        AppOpenAd.load(
            with: adUnitID,
            request: Request()
        ) { [weak self] ad, error in
            if let error = error {
                AppLogger.app.error("[AdMob] App open load failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            Task { @MainActor in
                self?.currentAppOpenAd = ad
                AppLogger.app.info("[AdMob] App open ad loaded")
                completion(ad)
            }
        }
    }
    
    /// Show app open ad if available
    func showAppOpenAd(
        from viewController: UIViewController,
        onDismiss: @escaping () -> Void
    ) -> Bool {
        guard let appOpenAd = currentAppOpenAd else {
            AppLogger.app.info("[AdMob] No app open ad available")
            return false
        }
        
        AdMobAppOpenDelegate.shared.onAdDismissed = onDismiss
        appOpenAd.present(from: viewController)
        currentAppOpenAd = nil
        
        // Single tracking point
        AdManager.shared.recordImpression(.appOpen)
        AdRevenueTracker.shared.recordImpression(unit: .appOpen)
        AdPlacementStrategy.shared.recordAdShown(.appOpen)
        
        AppLogger.app.info("[AdMob] App open ad presented")
        return true
    }
    
    // MARK: - Helpers
    
    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .rootViewController
    }
    
    // MARK: - Debug
    
    func debugInfo() -> String {
        """
        === AdMob Debug ===
        SDK Initialized: \(isSDKInitialized)
        Interstitial Cached: \(currentInterstitialAd != nil)
        App Open Cached: \(currentAppOpenAd != nil)
        Native Ads Loaded: \(currentNativeAds.count)
        """
    }
}

// MARK: - Banner Delegate

@MainActor
final class AdMobBannerDelegate: NSObject, BannerViewDelegate {
    static let shared = AdMobBannerDelegate()
    
    var onLoadCompletion: ((Bool) -> Void)?
    
    nonisolated func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        Task { @MainActor [self] in
            AppLogger.app.info("[AdMob] Banner ad received")
            AdManager.shared.recordLoaded(.banner)
            AdManager.shared.onBannerLoaded?()
            onLoadCompletion?(true)
            onLoadCompletion = nil
        }
    }
    
    nonisolated func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor [self] in
            AppLogger.app.error("[AdMob] Banner ad failed: \(error.localizedDescription)")
            AdManager.shared.recordFailure(.banner, error: error)
            onLoadCompletion?(false)
            onLoadCompletion = nil
        }
    }
    
    nonisolated func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        Task { @MainActor [self] in
            AdManager.shared.recordImpression(.banner)
            AdRevenueTracker.shared.recordImpression(unit: .banner)
        }
    }
    
    nonisolated func bannerViewDidRecordClick(_ bannerView: BannerView) {
        Task { @MainActor [self] in
            AdManager.shared.recordClick(.banner)
            AdRevenueTracker.shared.recordClick(unit: .banner)
        }
    }
}

// MARK: - Native Ad Loader Delegate

@MainActor
final class AdMobNativeLoaderDelegate: NSObject, AdLoaderDelegate, NativeAdLoaderDelegate {
    static let shared = AdMobNativeLoaderDelegate()
    
    var onAdsLoaded: (([NativeAd]) -> Void)?
    var onSingleAdLoaded: ((NativeAd?) -> Void)?
    var onLoadFailed: (() -> Void)?
    private var loadedAds: [NativeAd] = []
    
    nonisolated func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        Task { @MainActor [self] in
            self.loadedAds.append(nativeAd)
            nativeAd.delegate = self
            AppLogger.app.info("[AdMob] Native ad received")
        }
    }
    
    nonisolated func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        Task { @MainActor [self] in
            AppLogger.app.info("[AdMob] Native ads loading finished: \(self.loadedAds.count) ads")
            AdManager.shared.recordLoaded(.native)
            AdManager.shared.onNativeLoaded?()
            
            if let singleCompletion = onSingleAdLoaded {
                singleCompletion(loadedAds.first)
                onSingleAdLoaded = nil
            } else {
                onAdsLoaded?(loadedAds)
            }
            
            loadedAds.removeAll()
        }
    }
    
    nonisolated func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor [self] in
            AppLogger.app.error("[AdMob] Native ad failed: \(error.localizedDescription)")
            AdManager.shared.recordFailure(.native, error: error)
            onLoadFailed?()
            onSingleAdLoaded?(nil)
            onSingleAdLoaded = nil
            onLoadFailed = nil
            loadedAds.removeAll()
        }
    }
}

// MARK: - Native Ad Delegate

extension AdMobNativeLoaderDelegate: NativeAdDelegate {
    nonisolated func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        Task { @MainActor [self] in
            AdManager.shared.recordImpression(.native)
            AdRevenueTracker.shared.recordImpression(unit: .native)
        }
    }
    
    nonisolated func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        Task { @MainActor [self] in
            AdManager.shared.recordClick(.native)
            AdRevenueTracker.shared.recordClick(unit: .native)
        }
    }
}

// MARK: - Interstitial Delegate

@MainActor
final class AdMobInterstitialDelegate: NSObject, FullScreenContentDelegate {
    static let shared = AdMobInterstitialDelegate()
    
    var onAdDismissed: (() -> Void)?
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor [self] in
            AppLogger.app.error("[AdMob] Interstitial failed to present: \(error.localizedDescription)")
            AdManager.shared.recordFailure(.interstitial, error: error)
        }
    }
    
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor [self] in
            AppLogger.app.info("[AdMob] Interstitial ad dismissed")
            AdManager.shared.recordDismiss(.interstitial)
            self.onAdDismissed?()
            
            Task {
                AdAnalyticsEngine.shared.markLoadStart(.interstitial)
                await AdManager.shared.preloadInterstitial()
            }
        }
    }
}

// MARK: - App Open Delegate

@MainActor
final class AdMobAppOpenDelegate: NSObject, FullScreenContentDelegate {
    static let shared = AdMobAppOpenDelegate()
    
    var onAdDismissed: (() -> Void)?
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor [self] in
            AppLogger.app.error("[AdMob] App open failed to present: \(error.localizedDescription)")
            AdManager.shared.recordFailure(.appOpen, error: error)
        }
    }
    
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor [self] in
            AppLogger.app.info("[AdMob] App open ad dismissed")
            AdManager.shared.recordDismiss(.appOpen)
            self.onAdDismissed?()
            
            Task {
                AdAnalyticsEngine.shared.markLoadStart(.appOpen)
                await AdManager.shared.preloadAppOpen()
            }
        }
    }
}
