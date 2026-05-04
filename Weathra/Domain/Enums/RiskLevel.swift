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
        case .low: String(localized: "risk_low")
        case .medium: String(localized: "risk_medium")
        case .high: String(localized: "risk_high")
        case .extreme: String(localized: "risk_extreme")
        }
    }
}
