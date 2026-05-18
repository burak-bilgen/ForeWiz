import Foundation

enum AppLanguage: String, CaseIterable, Codable, Hashable, Sendable {
    case english
    case turkish

    var localizedTitle: String {
        switch self {
        case .english: L10n.text("language_english")
        case .turkish: L10n.text("language_turkish")
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .english: "en"
        case .turkish: "tr"
        }
    }
}
