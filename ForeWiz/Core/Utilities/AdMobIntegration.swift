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
    private var interstitialAd: InterstitialAd?
    private var appOpenAd: AppOpenAd?
    private var nativeAds: [NativeAd] = []
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
    
    /// Create a banner ad view
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
    
    /// Load a banner ad
    func loadBannerAd(for bannerView: BannerView) {
        let request = Request()
        bannerView.load(request)
        AppLogger.app.info("[AdMob] Banner ad loading...")
    }
    
    // MARK: - Native Ads
    
    /// Load native ads
    func loadNativeAds(
        adUnitID: String,
        rootViewController: UIViewController,
        completion: @escaping ([NativeAd]) -> Void
    ) {
        nativeAds.removeAll()
        
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: []
        )
        adLoader?.delegate = AdMobNativeLoaderDelegate.shared
        adLoader?.load(Request())
        
        AdMobNativeLoaderDelegate.shared.onAdsLoaded = { [weak self] ads in
            self?.nativeAds = ads
            completion(ads)
        }
        
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
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = AdMobInterstitialDelegate.shared
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
        guard let interstitialAd = interstitialAd else {
            AppLogger.app.info("[AdMob] No interstitial ad available")
            return false
        }
        
        AdMobInterstitialDelegate.shared.onAdDismissed = onDismiss
        interstitialAd.present(from: viewController)
        self.interstitialAd = nil
        
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
                self?.appOpenAd = ad
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
        guard let appOpenAd = appOpenAd else {
            AppLogger.app.info("[AdMob] No app open ad available")
            return false
        }
        
        AdMobAppOpenDelegate.shared.onAdDismissed = onDismiss
        appOpenAd.present(from: viewController)
        self.appOpenAd = nil
        
        AdManager.shared.recordImpression(.appOpen)
        AdRevenueTracker.shared.recordImpression(unit: .appOpen)
        AdPlacementStrategy.shared.recordAdShown(.appOpen)
        
        AppLogger.app.info("[AdMob] App open ad presented")
        return true
    }
    
    // MARK: - Debug
    
    func debugInfo() -> String {
        """
        === AdMob Debug ===
        SDK Initialized: \(isSDKInitialized)
        Interstitial Cached: \(interstitialAd != nil)
        App Open Cached: \(appOpenAd != nil)
        Native Ads Loaded: \(nativeAds.count)
        """
    }
}

// MARK: - Banner Delegate

@MainActor
final class AdMobBannerDelegate: NSObject, BannerViewDelegate {
    static let shared = AdMobBannerDelegate()
    
    nonisolated func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        Task { @MainActor in
            AppLogger.app.info("[AdMob] Banner ad received")
            AdManager.shared.onBannerLoaded?()
            AdManager.shared.recordImpression(.banner)
            AdRevenueTracker.shared.recordImpression(unit: .banner)
        }
    }
    
    nonisolated func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor in
            AppLogger.app.error("[AdMob] Banner ad failed: \(error.localizedDescription)")
            AdManager.shared.recordFailure(.banner, error: error)
        }
    }
    
    nonisolated func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        Task { @MainActor in
            AdRevenueTracker.shared.recordImpression(unit: .banner)
        }
    }
    
    nonisolated func bannerViewDidRecordClick(_ bannerView: BannerView) {
        Task { @MainActor in
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
    private var loadedAds: [NativeAd] = []
    
    nonisolated func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        Task { @MainActor in
            self.loadedAds.append(nativeAd)
            nativeAd.delegate = self
            AppLogger.app.info("[AdMob] Native ad received")
        }
    }
    
    nonisolated func adLoaderDidFinishLoading(_ adLoader: AdLoader) {
        Task { @MainActor in
            AppLogger.app.info("[AdMob] Native ads loading finished: \(self.loadedAds.count) ads")
            AdManager.shared.onNativeLoaded?()
            self.onAdsLoaded?(self.loadedAds)
            
            for ad in self.loadedAds {
                AdManager.shared.recordImpression(.native)
                AdRevenueTracker.shared.recordImpression(unit: .native)
            }
            
            self.loadedAds.removeAll()
        }
    }
    
    nonisolated func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor in
            AppLogger.app.error("[AdMob] Native ad failed: \(error.localizedDescription)")
            AdManager.shared.recordFailure(.native, error: error)
        }
    }
}

// MARK: - Native Ad Delegate

extension AdMobNativeLoaderDelegate: NativeAdDelegate {
    nonisolated func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        Task { @MainActor in
            AdRevenueTracker.shared.recordImpression(unit: .native)
        }
    }
    
    nonisolated func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        Task { @MainActor in
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
        Task { @MainActor in
            AppLogger.app.error("[AdMob] Interstitial failed to present: \(error.localizedDescription)")
            AdManager.shared.recordFailure(.interstitial, error: error)
        }
    }
    
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            AppLogger.app.info("[AdMob] Interstitial ad dismissed")
            self.onAdDismissed?()
            
            Task {
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
        Task { @MainActor in
            AppLogger.app.error("[AdMob] App open failed to present: \(error.localizedDescription)")
            AdManager.shared.recordFailure(.appOpen, error: error)
        }
    }
    
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            AppLogger.app.info("[AdMob] App open ad dismissed")
            self.onAdDismissed?()
            
            Task {
                await AdManager.shared.preloadAppOpen()
            }
        }
    }
}
