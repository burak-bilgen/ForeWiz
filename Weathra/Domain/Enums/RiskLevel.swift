import Foundation

enum RiskLevel: Int, CaseIterable, Codable, Comparable, Hashable, Sendable {
    case low = 1
    case medium = 2
    case high = 3
    case extreme = 4

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var localizedTitle: String {
        switch self {
        case .low:
            "Düşük"
        case .medium:
            "Orta"
        case .high:
            "Yüksek"
        case .extreme:
            "Çok yüksek"
        }
    }
}
