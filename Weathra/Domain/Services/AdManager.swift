import Combine
import Foundation
import GoogleMobileAds

protocol AdManager {
    var isReady: Bool { get }
    func load() async
    func showInterstitial() async
    func showRewarded() async -> Bool
}

@MainActor
final class GoogleAdManager: AdManager, ObservableObject {
    @Published private(set) var isReady: Bool = false
    
    private var interstitial: GADInterstitialAd?
    private var rewardedAd: GADRewardedAd?
    
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/1033173712"
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/5224354917"
    
    static let shared = GoogleAdManager()
    
    func load() async {
        await loadInterstitial()
        await loadRewarded()
        isReady = interstitial != nil || rewardedAd != nil
    }
    
    private func loadInterstitial() async {
        do {
            let ad = try await GADInterstitialAd.load(
                withAdUnitID: interstitialAdUnitID,
                request: GADRequest()
            )
            interstitial = ad
            interstitial?.fullScreenContentDelegate = nil
        } catch {
            interstitial = nil
        }
    }
    
    private func loadRewarded() async {
        do {
            let ad = try await GADRewardedAd.load(
                withAdUnitID: rewardedAdUnitID,
                request: GADRequest()
            )
            rewardedAd = ad
        } catch {
            rewardedAd = nil
        }
    }
    
    func showInterstitial() async {
        guard let interstitial = interstitial else {
            await loadInterstitial()
            return
        }
        
        guard let rootVC = await getRootViewController() else { return }
        
        interstitial.present(from: rootVC)
        self.interstitial = nil
    }
    
    func showRewarded() async -> Bool {
        guard let rewardedAd = rewardedAd else {
            await loadRewarded()
            return false
        }
        
        guard let rootVC = await getRootViewController() else { return false }
        
        return await withCheckedContinuation { continuation in
            rewardedAd.present(
                fromRootViewController: rootVC,
                userDidEarnRewardHandler: {
                    continuation.resume(returning: true)
                }
            )
            self.rewardedAd = nil
        }
    }
    
    private func getRootViewController() async -> UIViewController? {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
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