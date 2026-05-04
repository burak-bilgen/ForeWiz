import Foundation

enum LocationPermissionMapper {
    static func userMessage(for status: LocationAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            String(localized: "permission_location_not_requested")
        case .authorized:
            String(localized: "permission_location_granted")
        case .denied, .restricted:
            AppError.locationPermissionDenied.userMessage
        }
    }
}
