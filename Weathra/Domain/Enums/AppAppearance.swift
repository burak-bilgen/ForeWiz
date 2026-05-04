import Foundation

enum AppAppearance: String, CaseIterable, Codable, Hashable, Sendable {
    case system
    case light
    case dark

    var localizedTitle: String {
        switch self {
        case .system: String(localized: "appearance_system")
        case .light: String(localized: "appearance_light")
        case .dark: String(localized: "appearance_dark")
        }
    }
}
