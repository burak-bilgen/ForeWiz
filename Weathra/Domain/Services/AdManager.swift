import Foundation

protocol AdManager: Sendable {
    var isReady: Bool { get }
    func load() async
    func showInterstitial() async
    func showRewarded() async -> Bool
}

final class MockAdManager: AdManager {
    private(set) var isReady: Bool = false

    func load() async {
        // Simulate loading; in production, initialize your ad SDK here.
        try? await Task.sleep(nanoseconds: 500_000_000)
        isReady = true
    }

    func showInterstitial() async {
        // No-op in mock.
    }

    func showRewarded() async -> Bool {
        // No-op in mock.
        false
    }
}
