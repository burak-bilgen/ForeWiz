import Foundation

enum AppAccentPalette: String, CaseIterable, Codable, Hashable, Sendable {
    case sky
    case mint
    case ember

    var localizedTitle: String {
        switch self {
        case .sky:
            "Gökyüzü"
        case .mint:
            "Nane"
        case .ember:
            "Gün batımı"
        }
    }
}
