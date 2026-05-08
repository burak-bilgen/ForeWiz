import Combine
import Foundation
import os

#if canImport(GoogleMobileAds) && canImport(UIKit)
import GoogleMobileAds
import UIKit

final class GoogleAdManager: AdManager, @unchecked Sendable {
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/1033173712"
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/5224354917"

    private let isReadyLock = OSAllocatedUnfairLock(initialState: false)
    private let interstitialAdLock = OSAllocatedUnfairLock(initialState: nil as InterstitialAd?)
    private let rewardedAdLock = OSAllocatedUnfairLock(initialState: nil as RewardedAd?)

    private let logger = Logger(subsystem: "com.weathra.ads", category: "AdManager")

    var isReady: Bool {
        isReadyLock.withLock { $0 }
    }

    static let shared = GoogleAdManager()

    func load() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadInterstitial() }
            group.addTask { await self.loadRewarded() }
        }

        isReadyLock.withLock { $0 = true }
        logger.info("Ad manager initialized and ads loaded")
    }

    private func loadInterstitial() async {
        do {
            let ad = try await InterstitialAd.load(
                with: interstitialAdUnitID,
                request: Request()
            )
            interstitialAdLock.withLock { $0 = ad }
            logger.info("Interstitial ad loaded successfully")
        } catch {
            logger.error("Failed to load interstitial ad: \(error.localizedDescription)")
        }
    }

    private func loadRewarded() async {
        do {
            let ad = try await RewardedAd.load(
                with: rewardedAdUnitID,
                request: Request()
            )
            rewardedAdLock.withLock { $0 = ad }
            logger.info("Rewarded ad loaded successfully")
        } catch {
            logger.error("Failed to load rewarded ad: \(error.localizedDescription)")
        }
    }

    func showInterstitial() async {
        var ad: InterstitialAd?

        // Try to use cached ad first
        if let cachedAd = interstitialAdLock.withLock({ $0 }) {
            ad = cachedAd
            interstitialAdLock.withLock { $0 = nil }
        }

        // If no cached ad, load new one
        if ad == nil {
            do {
                ad = try await InterstitialAd.load(
                    with: interstitialAdUnitID,
                    request: Request()
                )
            } catch {
                logger.error("Failed to load interstitial ad for display: \(error.localizedDescription)")
                return
            }
        }

        guard let interstitial = ad,
              let rootVC = await MainActor.run(body: { getRootViewController() }) else {
            logger.warning("Could not show interstitial ad: no root view controller")
            return
        }

        await MainActor.run {
            interstitial.present(from: rootVC)
        }
        logger.info("Interstitial ad presented")
    }

    func showRewarded() async -> Bool {
        var ad: RewardedAd?

        // Try to use cached ad first
        if let cachedAd = rewardedAdLock.withLock({ $0 }) {
            ad = cachedAd
            rewardedAdLock.withLock { $0 = nil }
        }

        // If no cached ad, load new one
        if ad == nil {
            do {
                ad = try await RewardedAd.load(
                    with: rewardedAdUnitID,
                    request: Request()
                )
            } catch {
                logger.error("Failed to load rewarded ad for display: \(error.localizedDescription)")
                return false
            }
        }

        guard let rewardedAd = ad,
              let rootVC = await MainActor.run(body: { getRootViewController() }) else {
            logger.warning("Could not show rewarded ad: no root view controller")
            return false
        }

        await MainActor.run {
            rewardedAd.present(
                from: rootVC,
                userDidEarnRewardHandler: { reward in
                    logger.info("User earned reward: \(reward.amount) \(reward.type)")
                }
            )
        }
        logger.info("Rewarded ad presented")
        return true
    }

    @MainActor
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return nil
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
}
#else
final class GoogleAdManager: AdManager {
    var isReady: Bool { false }

    static let shared = GoogleAdManager()

    func load() async {
        // No-op when GoogleMobileAds is not available
    }

    func showInterstitial() async {
        // No-op when GoogleMobileAds is not available
    }

    func showRewarded() async -> Bool {
        return false
    }
}
#endif

protocol AdManager: Sendable {
    var isReady: Bool { get }
    func load() async
    func showInterstitial() async
    func showRewarded() async -> Bool
}
