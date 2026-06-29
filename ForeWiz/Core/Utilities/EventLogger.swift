import Foundation
import os

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


    }

    func trackScreenView(_ screenName: String) {
        logger.info("Screen view: \(screenName)")
    }

    func trackError(_ error: Error, context: String) {
        logger.error("Error in \(context): \(error.localizedDescription)")
    }
}
