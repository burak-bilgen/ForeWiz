import Foundation

enum AppLanguage: String, CaseIterable, Codable, Hashable, Sendable {
    case system
    case turkish
    case english

    var localizedTitle: String {
        switch self {
        case .system:
            "Sistem"
        case .turkish:
            "Türkçe"
        case .english:
            "English"
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
