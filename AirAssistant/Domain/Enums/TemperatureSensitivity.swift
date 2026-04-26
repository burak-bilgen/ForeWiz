import Foundation

enum TemperatureSensitivity: String, CaseIterable, Codable, Hashable, Sendable {
    case getsColdEasily
    case normal
    case getsHotEasily

    var localizedTitle: String {
        switch self {
        case .getsColdEasily:
            "Çabuk üşürüm"
        case .normal:
            "Normal"
        case .getsHotEasily:
            "Çabuk bunalırım"
        }
    }
}
