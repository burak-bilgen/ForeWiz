import Foundation
import os

final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private let logger = Logger(subsystem: "com.weathra.analytics", category: "Events")

    private init() {}

    enum Event {
        case appLaunch
        case locationPermissionGranted
        case locationPermissionDenied
        case notificationPermissionGranted
        case notificationPermissionDenied
        case subscriptionPurchased(SubscriptionTier)
        case subscriptionRestored
        case paywallViewed
        case paywallDismissed
        case onboardingCompleted
        case homeRefresh
        case recommendationViewed(String)
        case settingsOpened
        case widgetAdded

        var name: String {
            switch self {
            case .appLaunch: return "app_launch"
            case .locationPermissionGranted: return "location_permission_granted"
            case .locationPermissionDenied: return "location_permission_denied"
            case .notificationPermissionGranted: return "notification_permission_granted"
            case .notificationPermissionDenied: return "notification_permission_denied"
            case .subscriptionPurchased: return "subscription_purchased"
            case .subscriptionRestored: return "subscription_restored"
            case .paywallViewed: return "paywall_viewed"
            case .paywallDismissed: return "paywall_dismissed"
            case .onboardingCompleted: return "onboarding_completed"
            case .homeRefresh: return "home_refresh"
            case .recommendationViewed: return "recommendation_viewed"
            case .settingsOpened: return "settings_opened"
            case .widgetAdded: return "widget_added"
            }
        }
    }

    func track(_ event: Event, parameters: [String: Any]? = nil) {
        logger.info("Tracking event: \(event.name)")

        #if DEBUG
        print("📊 Analytics: \(event.name)")
        if let params = parameters {
            print("   Parameters: \(params)")
        }
        #endif
    }

    func trackScreenView(_ screenName: String) {
        logger.info("Screen view: \(screenName)")
    }

    func trackError(_ error: Error, context: String) {
        logger.error("Error in \(context): \(error.localizedDescription)")
    }
}