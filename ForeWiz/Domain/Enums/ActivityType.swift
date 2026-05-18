import Foundation

enum ActivityType: String, Codable, Hashable, Sendable {
    case goingOutside

    var localizedTitle: String {
        L10n.text("activity_outside")
    }
}
