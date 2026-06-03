import Foundation

enum HealthError: Error, LocalizedError {
    case authorizationDenied
    case deviceLocked
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Health data access was denied."
        case .deviceLocked:
            return "Health data is inaccessible because the device is locked."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
