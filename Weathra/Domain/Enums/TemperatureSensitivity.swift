import Foundation

enum TemperatureSensitivity: String, CaseIterable, Codable, Hashable, Sendable {
    case getsColdEasily
    case normal
    case getsHotEasily

    var localizedTitle: String {
        switch self {
        case .getsColdEasily: L10n.text("sensitivity_cold")
        case .normal: L10n.text("sensitivity_normal")
        case .getsHotEasily: L10n.text("sensitivity_hot")
        }
    }
}
