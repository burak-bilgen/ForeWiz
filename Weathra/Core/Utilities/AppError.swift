import Foundation

enum AppError: Error, Equatable {
    case locationPermissionDenied
    case locationUnavailable
    case weatherUnavailable
    case weatherKitPermissionMissing
    case weatherKitFailed(String)
    case cacheUnavailable
    case notificationPermissionDenied
    case persistenceFailed
    case unknown

    var userMessage: String {
        switch self {
        case .locationPermissionDenied:
            String(localized: "error_location_denied")
        case .locationUnavailable:
            String(localized: "error_location_unavailable")
        case .weatherUnavailable:
            String(localized: "error_weather_unavailable")
        case .weatherKitPermissionMissing:
            String(localized: "error_weatherkit_auth")
        case .weatherKitFailed(let reason):
            String(localized: "error_weatherkit_failed") + " " + reason
        case .cacheUnavailable:
            String(localized: "error_cache_unavailable")
        case .notificationPermissionDenied:
            String(localized: "error_notification_denied")
        case .persistenceFailed:
            String(localized: "error_persistence")
        case .unknown:
            String(localized: "error_unknown")
        }
    }
}
