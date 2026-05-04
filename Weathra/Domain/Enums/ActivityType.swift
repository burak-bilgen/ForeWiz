import Foundation

enum ActivityType: String, CaseIterable, Codable, Hashable, Sendable {
    case running
    case walking
    case cycling
    case goingOutside

    var localizedTitle: String {
        switch self {
        case .running: String(localized: "activity_running")
        case .walking: String(localized: "activity_walking")
        case .cycling: String(localized: "activity_cycling")
        case .goingOutside: String(localized: "activity_outside")
        }
    }
}
