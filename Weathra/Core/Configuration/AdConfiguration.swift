import Foundation

enum AdConfiguration {
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/1033173712"
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/5224354917"

    #if DEBUG
    static let isTestMode = true
    #else
    static let isTestMode = false
    #endif
}
