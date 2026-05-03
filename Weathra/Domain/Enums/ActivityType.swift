import Foundation

enum ActivityType: String, CaseIterable, Codable, Hashable, Sendable {
    case running
    case walking
    case cycling
    case goingOutside

    var localizedTitle: String {
        switch self {
        case .running:
            "Koşu"
        case .walking:
            "Yürüyüş"
        case .cycling:
            "Bisiklet"
        case .goingOutside:
            "Dışarı"
        }
    }
}
