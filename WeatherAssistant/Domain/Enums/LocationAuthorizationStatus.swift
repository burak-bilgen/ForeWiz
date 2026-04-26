import Foundation

enum LocationAuthorizationStatus: Codable, Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}
