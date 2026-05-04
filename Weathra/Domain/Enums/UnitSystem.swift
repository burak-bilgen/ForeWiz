import Foundation

enum UnitSystem: String, CaseIterable, Codable, Hashable, Sendable {
    case metric
    case imperial

    var localizedTitle: String {
        switch self {
        case .metric: String(localized: "units_metric")
        case .imperial: String(localized: "units_imperial")
        }
    }
}
