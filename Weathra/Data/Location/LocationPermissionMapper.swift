import Foundation

enum LocationPermissionMapper {
    static func userMessage(for status: LocationAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            L10n.text("permission_location_not_requested")
        case .authorized:
            L10n.text("permission_location_granted")
        case .denied, .restricted:
            AppError.locationPermissionDenied.userMessage
        }
    }
}
