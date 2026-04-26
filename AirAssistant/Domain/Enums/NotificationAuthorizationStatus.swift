import Foundation

enum NotificationAuthorizationStatus: Codable, Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case provisional
}
