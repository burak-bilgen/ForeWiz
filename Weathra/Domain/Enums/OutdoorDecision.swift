import Foundation

enum OutdoorDecision: String, Codable, Hashable, Sendable {
    case good
    case moderate
    case risky
    case avoid

    init(score: WeatherScore) {
        switch score.rawValue {
        case 80...100:
            self = .good
        case 60..<80:
            self = .moderate
        case 40..<60:
            self = .risky
        default:
            self = .avoid
        }
    }

    var localizedTitle: String {
        switch self {
        case .good:
            L10n.text("decision_good")
        case .moderate:
            L10n.text("decision_moderate")
        case .risky:
            L10n.text("decision_risky")
        case .avoid:
            L10n.text("decision_avoid")
        }
    }
}
