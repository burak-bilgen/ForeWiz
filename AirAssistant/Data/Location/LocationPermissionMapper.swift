import Foundation

enum LocationPermissionMapper {
    static func userMessage(for status: LocationAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            "Konum izni henüz istenmedi."
        case .authorized:
            "Konum izni açık."
        case .denied, .restricted:
            AppError.locationPermissionDenied.userMessage
        }
    }
}
