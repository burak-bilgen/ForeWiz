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
        guard canRequestAd() else {
            onFailure()
            return
        }

        // Get root VC for banner loading
        guard let rootVC = rootViewController() else {
            onFailure()
            return
        }
        
        let bannerView = BannerView(adSize: AdSizeBanner)
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
        
        bannerView.load(makeAdRequest())
        AppLogger.app.info("[AdMob] Banner ad loading...")
    }
    
    /// Create a banner view for inline display (used by AdBannerView)
    func createBannerView(
        adUnitID: String,
        rootViewController: UIViewController
    ) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
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
        guard canRequestAd() else {
            completion(nil)
            return
        }

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
        
        adLoader?.load(makeAdRequest())
        AppLogger.app.info("[AdMob] Loading native ad...")
    }
    
    /// Load native ads (bulk)
    func loadNativeAds(
        adUnitID: String,
        rootViewController: UIViewController,
        completion: @escaping ([NativeAd]) -> Void
    ) {
        guard canRequestAd() else {
            completion([])
            return
        }

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
        
        adLoader?.load(makeAdRequest())
        AppLogger.app.info("[AdMob] Loading native ads...")
    }
    
    // MARK: - Interstitial Ads
    
    /// Load an interstitial ad
    func loadInterstitialAd(
        adUnitID: String,
        completion: @escaping (InterstitialAd?) -> Void
    ) {
        guard canRequestAd() else {
            completion(nil)
            return
        }

        InterstitialAd.load(
            with: adUnitID,
            request: makeAdRequest()
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
        guard AdConsentManager.shared.canServeAds else { return false }
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
        guard canRequestAd() else {
            completion(nil)
            return
        }

        AppOpenAd.load(
            with: adUnitID,
            request: makeAdRequest()
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
        guard AdConsentManager.shared.canServeAds else { return false }
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

    func makeAdRequest() -> Request {
        let request = Request()

        if !AdConsentManager.shared.canServePersonalizedAds {
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
        }

        return request
    }

    private func canRequestAd() -> Bool {
        guard AdConsentManager.shared.canServeAds else {
            AppLogger.app.info("[AdMob] Ad request skipped because consent is not ready")
            return false
        }

        guard isSDKInitialized else {
            AppLogger.app.info("[AdMob] Ad request skipped because SDK is not initialized")
            return false
        }

        return true
    }
    
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
        Task { @MainActor in
            AdManager.shared.recordImpression(.banner)
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
            
            // Nil all callbacks to prevent any hypothetical double-fire from
            // both adLoaderDidFinishLoading and adLoader(_:didFailToReceiveAdWithError:).
            onSingleAdLoaded = nil
            onLoadFailed = nil
            
            loadedAds.removeAll()
        }
    }
    
    nonisolated func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor [self] in
            AppLogger.app.error("[AdMob] Native ad failed: \(error.localizedDescription)")
            AdManager.shared.recordFailure(.native, error: error)

            // IMPORTANT: Capture and nil both callbacks BEFORE calling either one.
            // loadNativeAd() sets both onSingleAdLoaded and onLoadFailed to the same
            // completion closure. Calling both would cause a double-resume crash on the
            // CheckedContinuation, producing a SIGTRAP / EXC_BREAKPOINT.
            let singleCompletion = onSingleAdLoaded
            let loadFailedCompletion = onLoadFailed
            onSingleAdLoaded = nil
            onLoadFailed = nil

            // Only call the callback that matches the loading path used.
            // If loadNativeAd was used, onSingleAdLoaded is non-nil.
            // If loadNativeAds was used (bulk), onAdsLoaded is set instead.
            if singleCompletion != nil {
                singleCompletion?(nil)
            } else {
                loadFailedCompletion?()
            }

            loadedAds.removeAll()
        }
    }
}

// MARK: - Native Ad Delegate

extension AdMobNativeLoaderDelegate: NativeAdDelegate {
    nonisolated func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        Task { @MainActor in
            AdManager.shared.recordImpression(.native)
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
        Task { @MainActor in
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
