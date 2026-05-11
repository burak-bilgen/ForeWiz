import Foundation

enum AppAppearance: String, CaseIterable, Codable, Hashable, Sendable {
    case system
    case light
    case dark

    var localizedTitle: String {
        switch self {
        case .system: L10n.text("appearance_system")
        case .light: L10n.text("appearance_light")
        case .dark: L10n.text("appearance_dark")
        }
    }
}
