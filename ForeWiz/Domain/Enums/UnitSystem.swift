import Foundation

enum UnitSystem: String, CaseIterable, Codable, Hashable, Sendable {
    case metric
    case imperial

    var localizedTitle: String {
        switch self {
        case .metric: L10n.text("units_metric")
        case .imperial: L10n.text("units_imperial")
        }
    }
}
