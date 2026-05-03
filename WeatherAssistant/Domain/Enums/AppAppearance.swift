import Foundation

enum AppAppearance: String, CaseIterable, Codable, Hashable, Sendable {
    case system
    case light
    case dark

    var localizedTitle: String {
        switch self {
        case .system:
            "Sistem"
        case .light:
            "Açık"
        case .dark:
            "Koyu"
        }
    }
}
