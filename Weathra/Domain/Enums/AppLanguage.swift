import Foundation

enum AppLanguage: String, CaseIterable, Codable, Hashable, Sendable {
    case system
    case turkish
    case english

    var localizedTitle: String {
        switch self {
        case .system: L10n.text("language_system")
        case .turkish: L10n.text("language_turkish")
        case .english: L10n.text("language_english")
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system:
            nil
        case .turkish:
            "tr"
        case .english:
            "en"
        }
    }
}
