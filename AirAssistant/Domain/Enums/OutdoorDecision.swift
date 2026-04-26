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
            "Evet, iyi görünüyor"
        case .moderate:
            "Olur, ama dikkatli"
        case .risky:
            "Riskli saatler var"
        case .avoid:
            "Bugün zorlayıcı"
        }
    }
}
