import Foundation

enum AppAccentPalette: String, CaseIterable, Codable, Hashable, Sendable {
    case sky
    case mint
    case ember

    var localizedTitle: String {
        switch self {
        case .sky: L10n.text("palette_sky")
        case .mint: L10n.text("palette_mint")
        case .ember: L10n.text("palette_ember")
        }
    }
}
