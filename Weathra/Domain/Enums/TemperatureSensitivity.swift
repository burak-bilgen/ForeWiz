import Foundation

enum TemperatureSensitivity: String, CaseIterable, Codable, Hashable, Sendable {
    case getsColdEasily
    case normal
    case getsHotEasily

    var localizedTitle: String {
        switch self {
        case .getsColdEasily: String(localized: "sensitivity_cold")
        case .normal: String(localized: "sensitivity_normal")
        case .getsHotEasily: String(localized: "sensitivity_hot")
        }
    }
}
