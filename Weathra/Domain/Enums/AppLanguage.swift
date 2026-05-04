import Foundation

enum AppLanguage: String, CaseIterable, Codable, Hashable, Sendable {
    case system
    case turkish
    case english

    var localizedTitle: String {
        switch self {
        case .system: String(localized: "language_system")
        case .turkish: String(localized: "language_turkish")
        case .english: String(localized: "language_english")
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
