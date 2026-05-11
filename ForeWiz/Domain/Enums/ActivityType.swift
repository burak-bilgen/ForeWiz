import Foundation

enum ActivityType: String, CaseIterable, Codable, Hashable, Sendable {
    case running
    case walking
    case cycling
    case goingOutside

    var localizedTitle: String {
        switch self {
        case .running: L10n.text("activity_running")
        case .walking: L10n.text("activity_walking")
        case .cycling: L10n.text("activity_cycling")
        case .goingOutside: L10n.text("activity_outside")
        }
    }
}
