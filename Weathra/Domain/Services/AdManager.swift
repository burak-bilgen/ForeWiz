import Combine
import Foundation
import GoogleMobileAds

protocol AdManager: Sendable {
    var isReady: Bool { get }
    func load() async
    func showInterstitial() async
    func showRewarded() async -> Bool
}

final class GoogleAdManager: AdManager, @unchecked Sendable {
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/1033173712"
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/5224354917"
    
    private let isReadyLock = NSLock()
    private var _isReady = false
    
    var isReady: Bool {
        isReadyLock.lock()
        defer { isReadyLock.unlock() }
        return _isReady
    }
    
    static let shared = GoogleAdManager()
    
    func load() async {
        await loadInterstitial()
        await loadRewarded()
        
        isReadyLock.lock()
        _isReady = true
        isReadyLock.unlock()
    }
    
    private func loadInterstitial() async {
        do {
            _ = try await InterstitialAd.load(
                with: interstitialAdUnitID,
                request: Request()
            )
        } catch {
            // Ad failed to load
        }
    }
    
    private func loadRewarded() async {
        do {
            _ = try await RewardedAd.load(
                with: rewardedAdUnitID,
                request: Request()
            )
        } catch {
            // Ad failed to load
        }
    }
    
    func showInterstitial() async {
        guard let interstitial = try? await InterstitialAd.load(
            with: interstitialAdUnitID,
            request: Request()
        ) else { return }
        
        guard let rootVC = await MainActor.run(body: { getRootViewController() }) else { return }
        
        await MainActor.run {
            interstitial.present(from: rootVC)
        }
    }
    
    func showRewarded() async -> Bool {
        guard let rewardedAd = try? await RewardedAd.load(
            with: rewardedAdUnitID,
            request: Request()
        ) else { return false }
        
        guard let rootVC = await MainActor.run(body: { getRootViewController() }) else { return false }
        
        await MainActor.run {
            rewardedAd.present(
                from: rootVC,
                userDidEarnRewardHandler: {
                    // Reward granted
                }
            )
        }
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