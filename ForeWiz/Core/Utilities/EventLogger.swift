import Foundation
import os

/// Lightweight event logger that records key user actions and system events.
///
/// Currently logs to OSLog and prints in debug builds.
/// Replace the `track` implementation with an analytics SDK (Firebase, Mixpanel, etc.)
/// when ready — the call sites are already set up.
final class EventLogger {
    static let shared = EventLogger()

    private let logger = Logger(subsystem: "com.forewiz.analytics", category: "Events")

    private init() {}

    enum Event {
        case appLaunch
        case locationPermissionGranted
        case locationPermissionDenied
        case notificationPermissionGranted
        case notificationPermissionDenied
        case onboardingCompleted
        case homeRefresh
        case recommendationViewed(String)
        case settingsOpened
        case insightsViewed
        case trackingPermissionGranted
        case trackingPermissionDenied
        case widgetAdded

        var name: String {
            switch self {
            case .appLaunch: return "app_launch"
            case .locationPermissionGranted: return "location_permission_granted"
            case .locationPermissionDenied: return "location_permission_denied"
            case .notificationPermissionGranted: return "notification_permission_granted"
            case .notificationPermissionDenied: return "notification_permission_denied"
            case .trackingPermissionGranted: return "tracking_permission_granted"
            case .trackingPermissionDenied: return "tracking_permission_denied"
            case .onboardingCompleted: return "onboarding_completed"
            case .homeRefresh: return "home_refresh"
            case .recommendationViewed: return "recommendation_viewed"
            case .settingsOpened: return "settings_opened"
            case .insightsViewed: return "insights_viewed"
            case .widgetAdded: return "widget_added"
            }
        }
    }

    func track(_ event: Event, parameters: [String: Any]? = nil) {
        logger.info("Tracking event: \(event.name)")

        #if DEBUG
        print("📊 Event: \(event.name)")
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
