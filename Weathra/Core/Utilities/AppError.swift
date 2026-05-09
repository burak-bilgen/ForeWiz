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
    case invalidData
    case unknown

    var userMessage: String {
        switch self {
        case .locationPermissionDenied:
            L10n.text("error_location_denied")
        case .locationUnavailable:
            L10n.text("error_location_unavailable")
        case .weatherUnavailable:
            L10n.text("error_weather_unavailable")
        case .weatherKitPermissionMissing:
            L10n.text("error_weatherkit_auth")
        case .weatherKitFailed(let reason):
            L10n.text("error_weatherkit_failed") + " " + reason
        case .cacheUnavailable:
            L10n.text("error_cache_unavailable")
        case .notificationPermissionDenied:
            L10n.text("error_notification_denied")
        case .persistenceFailed:
            L10n.text("error_persistence")
        case .invalidData:
            L10n.text("error_unknown")
        case .unknown:
            L10n.text("error_unknown")
        }
    }
}
