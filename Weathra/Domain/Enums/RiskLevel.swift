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
        case .low: L10n.text("risk_low")
        case .medium: L10n.text("risk_medium")
        case .high: L10n.text("risk_high")
        case .extreme: L10n.text("risk_extreme")
        }
    }
}
