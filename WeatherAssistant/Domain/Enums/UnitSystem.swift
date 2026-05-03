import Foundation

enum UnitSystem: String, CaseIterable, Codable, Hashable, Sendable {
    case metric
    case imperial

    var localizedTitle: String {
        switch self {
        case .metric:
            "Metrik"
        case .imperial:
            "Imperial"
        }
    }
}
