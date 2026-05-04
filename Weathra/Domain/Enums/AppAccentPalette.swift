import Foundation

enum AppAccentPalette: String, CaseIterable, Codable, Hashable, Sendable {
    case sky
    case mint
    case ember

    var localizedTitle: String {
        switch self {
        case .sky: String(localized: "palette_sky")
        case .mint: String(localized: "palette_mint")
        case .ember: String(localized: "palette_ember")
        }
    }
}
