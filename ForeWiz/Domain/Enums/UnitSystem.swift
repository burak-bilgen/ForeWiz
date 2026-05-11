import Foundation

enum UnitSystem: String, Codable, Hashable, Sendable {
    case metric
    case imperial

    static var current: UnitSystem {
        let locale = Locale.current
        guard let regionCode = locale.region?.identifier else { return .metric }
        let imperialRegions: Set<String> = ["US", "LR", "MM", "GB"]
        return imperialRegions.contains(regionCode) ? .imperial : .metric
    }

    var localizedTitle: String {
        switch self {
        case .metric: L10n.text("units_metric")
        case .imperial: L10n.text("units_imperial")
        }
    }

    var shortLabel: String {
        switch self {
        case .metric: "°C"
        case .imperial: "°F"
        }
    }

    var description: String {
        switch self {
        case .metric: L10n.text("units_metric_desc")
        case .imperial: L10n.text("units_imperial_desc")
        }
    }

    var icon: String {
        switch self {
        case .metric: "thermometer.celsius"
        case .imperial: "thermometer.fahrenheit"
        }
    }
}
