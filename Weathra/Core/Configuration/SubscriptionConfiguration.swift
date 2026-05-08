import Foundation

enum SubscriptionConfiguration {
    static let productIDs: [String] = [
        "bilgenworks.weatherassistant.premium.monthly",
        "bilgenworks.weatherassistant.premium.yearly"
    ]

    #if DEBUG
    static let isTestMode = true
    #else
    static let isTestMode = false
    #endif
}
