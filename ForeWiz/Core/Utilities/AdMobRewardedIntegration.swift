import Foundation
import GoogleMobileAds
import OSLog

// MARK: - Rewarded Ads Integration
/// Rewarded and Rewarded Interstitial ad formats with reward callback.
/// Users can earn in-app rewards by watching ads voluntarily.
@MainActor
final class AdMobRewardedIntegration {
    static let shared = AdMobRewardedIntegration()
    
    // MARK: - Reward Configuration
    
    struct RewardConfig {
        let type: String
        let amount: Int
        
        static let `default` = RewardConfig(type: "coins", amount: 10)
        static let premium = RewardConfig(type: "coins", amount: 25)
        static let bonus = RewardConfig(type: "coins", amount: 50)
    }
    
    // MARK: - State
    
    private(set) var isRewardedLoaded = false
    private(set) var isRewardedInterstitialLoaded = false
    private var rewardedAd: RewardedAd?
    private var rewardedInterstitialAd: RewardedInterstitialAd?
    private var pendingReward: RewardConfig?
    var onRewardGranted: ((RewardConfig) -> Void)?
    var onRewardFailed: (() -> Void)?
    /// Guards against double-firing: once a callback fires, both are cleared.
    func clearCallbacks() {
        onRewardGranted = nil
        onRewardFailed = nil
    }
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Rewarded Ads
    
    /// Load a rewarded ad
    func loadRewardedAd(
        adUnitID: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard AdConsentManager.shared.canServeAds,
              AdMobIntegration.shared.isSDKInitialized else {
            completion(false)
            return
        }

        RewardedAd.load(
            with: adUnitID,
            request: AdMobIntegration.shared.makeAdRequest()
        ) { [weak self] ad, error in
            if let error = error {
                AppLogger.app.error("[AdMob] Rewarded ad load failed: \(error.localizedDescription)")
                Task { @MainActor in
                    self?.isRewardedLoaded = false
                    completion(false)
                }
                return
            }
            
            Task { @MainActor in
                self?.rewardedAd = ad
                self?.isRewardedLoaded = true
                AppLogger.app.info("[AdMob] Rewarded ad loaded")
                completion(true)
            }
        }
    }
    
    /// Show a rewarded ad with reward callback
    func showRewardedAd(
        from viewController: UIViewController,
        reward: RewardConfig = .default,
        onRewardGranted: @escaping (RewardConfig) -> Void,
        onRewardFailed: @escaping () -> Void
    ) -> Bool {
        guard AdConsentManager.shared.canServeAds else {
            onRewardFailed()
            return false
        }

        guard let rewardedAd = rewardedAd else {
            AppLogger.app.info("[AdMob] No rewarded ad available")
            onRewardFailed()
            return false
        }
        
        self.pendingReward = reward
        self.onRewardGranted = onRewardGranted
        self.onRewardFailed = onRewardFailed
        
        rewardedAd.fullScreenContentDelegate = AdMobRewardedDelegate.shared
        rewardedAd.present(from: viewController) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let reward = self.pendingReward else { return }
                AppLogger.app.info("[AdMob] Rewarded ad granted: \(reward.type) x\(reward.amount)")
                self.onRewardGranted?(reward)
                self.clearCallbacks()
            }
        }
        
        // Clear the ad (one-time use)
        self.rewardedAd = nil
        self.isRewardedLoaded = false
        
        // Track reward event
        AdManager.shared.recordReward(.rewarded, amount: Double(reward.amount))
        
        // Preload next rewarded ad
        Task {
            AdAnalyticsEngine.shared.markLoadStart(.rewarded)
            loadRewardedAd(adUnitID: AdManager.AdUnit.rewarded.currentID) { success in
                Task { @MainActor in
                    if success {
                        AdAnalyticsEngine.shared.recordEvent(.loaded, unit: .rewarded)
                        AdManager.shared.recordLoaded(.rewarded)
                    }
                }
            }
        }
        
        return true
    }
    
    // MARK: - Rewarded Interstitial Ads
    
    /// Load a rewarded interstitial ad
    func loadRewardedInterstitialAd(
        adUnitID: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard AdConsentManager.shared.canServeAds,
              AdMobIntegration.shared.isSDKInitialized else {
            completion(false)
            return
        }

        RewardedInterstitialAd.load(
            with: adUnitID,
            request: AdMobIntegration.shared.makeAdRequest()
        ) { [weak self] ad, error in
            if let error = error {
                AppLogger.app.error("[AdMob] Rewarded interstitial load failed: \(error.localizedDescription)")
                Task { @MainActor in
                    self?.isRewardedInterstitialLoaded = false
                    completion(false)
                }
                return
            }
            
            Task { @MainActor in
                self?.rewardedInterstitialAd = ad
                self?.isRewardedInterstitialLoaded = true
                AppLogger.app.info("[AdMob] Rewarded interstitial ad loaded")
                completion(true)
            }
        }
    }
    
    /// Show a rewarded interstitial ad
    func showRewardedInterstitialAd(
        from viewController: UIViewController,
        introMessage: String,
        reward: RewardConfig = .default,
        onRewardGranted: @escaping (RewardConfig) -> Void,
        onRewardFailed: @escaping () -> Void
    ) -> Bool {
        guard AdConsentManager.shared.canServeAds else {
            onRewardFailed()
            return false
        }

        guard let rewardedInterstitialAd = rewardedInterstitialAd else {
            AppLogger.app.info("[AdMob] No rewarded interstitial ad available")
            onRewardFailed()
            return false
        }
        
        self.pendingReward = reward
        self.onRewardGranted = onRewardGranted
        self.onRewardFailed = onRewardFailed
        
        rewardedInterstitialAd.fullScreenContentDelegate = AdMobRewardedInterstitialDelegate.shared
        rewardedInterstitialAd.present(
            from: viewController,
            userDidEarnRewardHandler: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let reward = self.pendingReward {
                        AppLogger.app.info("[AdMob] Rewarded interstitial granted: \(reward.type) x\(reward.amount)")
                        self.onRewardGranted?(reward)
                        self.clearCallbacks()
                    }
                }
            }
        )
        
        // Clear the ad (one-time use)
        self.rewardedInterstitialAd = nil
        self.isRewardedInterstitialLoaded = false
        
        // Track reward event
        AdManager.shared.recordReward(.rewardedInterstitial, amount: Double(reward.amount))
        
        // Preload next rewarded interstitial
        Task {
            AdAnalyticsEngine.shared.markLoadStart(.rewardedInterstitial)
            loadRewardedInterstitialAd(adUnitID: AdManager.AdUnit.rewardedInterstitial.currentID) { success in
                Task { @MainActor in
                    if success {
                        AdAnalyticsEngine.shared.recordEvent(.loaded, unit: .rewardedInterstitial)
                        AdManager.shared.recordLoaded(.rewardedInterstitial)
                    }
                }
            }
        }
        
        return true
    }
    
    // MARK: - Preload
    
    /// Preload rewarded ads for instant display
    func preloadAll(
        rewardedAdUnitID: String,
        rewardedInterstitialAdUnitID: String
    ) async {
        // Mark load start for analytics
        AdAnalyticsEngine.shared.markLoadStart(.rewarded)
        AdAnalyticsEngine.shared.markLoadStart(.rewardedInterstitial)
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                await withCheckedContinuation { continuation in
                    self.loadRewardedAd(adUnitID: rewardedAdUnitID) { success in
                        if success {
                            AdAnalyticsEngine.shared.recordEvent(.loaded, unit: .rewarded)
                            AdManager.shared.recordLoaded(.rewarded)
                        } else {
                            AdAnalyticsEngine.shared.recordEvent(.failed, unit: .rewarded)
                        }
                        continuation.resume()
                    }
                }
            }
            group.addTask { @MainActor in
                await withCheckedContinuation { continuation in
                    self.loadRewardedInterstitialAd(adUnitID: rewardedInterstitialAdUnitID) { success in
                        if success {
                            AdAnalyticsEngine.shared.recordEvent(.loaded, unit: .rewardedInterstitial)
                            AdManager.shared.recordLoaded(.rewardedInterstitial)
                        } else {
                            AdAnalyticsEngine.shared.recordEvent(.failed, unit: .rewardedInterstitial)
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }
}

// MARK: - Rewarded Delegate

@MainActor
final class AdMobRewardedDelegate: NSObject, FullScreenContentDelegate {
    static let shared = AdMobRewardedDelegate()
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            AppLogger.app.error("[AdMob] Rewarded ad failed: \(error.localizedDescription)")
            AdMobRewardedIntegration.shared.onRewardFailed?()
            AdMobRewardedIntegration.shared.clearCallbacks()
        }
    }
    
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            AppLogger.app.info("[AdMob] Rewarded ad dismissed")
            // If reward was already granted via userDidEarnRewardHandler, callbacks are nil already.
            // If neither reward nor failure fired, treat dismissal as failure so the UI doesn't hang.
            if AdMobRewardedIntegration.shared.onRewardFailed != nil {
                AdMobRewardedIntegration.shared.onRewardFailed?()
                AdMobRewardedIntegration.shared.clearCallbacks()
            }
            AdManager.shared.recordDismiss(.rewarded)
            AdAnalyticsEngine.shared.recordEvent(.dismissed, unit: .rewarded)
        }
    }
}

// MARK: - Rewarded Interstitial Delegate

@MainActor
final class AdMobRewardedInterstitialDelegate: NSObject, FullScreenContentDelegate {
    static let shared = AdMobRewardedInterstitialDelegate()
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            AppLogger.app.error("[AdMob] Rewarded interstitial failed: \(error.localizedDescription)")
            AdMobRewardedIntegration.shared.onRewardFailed?()
            AdMobRewardedIntegration.shared.clearCallbacks()
        }
    }
    
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            AppLogger.app.info("[AdMob] Rewarded interstitial dismissed")
            if AdMobRewardedIntegration.shared.onRewardFailed != nil {
                AdMobRewardedIntegration.shared.onRewardFailed?()
                AdMobRewardedIntegration.shared.clearCallbacks()
            }
            AdManager.shared.recordDismiss(.rewardedInterstitial)
            AdAnalyticsEngine.shared.recordEvent(.dismissed, unit: .rewardedInterstitial)
        }
    }
}
