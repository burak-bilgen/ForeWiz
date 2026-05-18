import Foundation

struct RecommendationCandidate: Identifiable, Equatable, Sendable {
    let id: UUID
    let type: CandidateType
    let score: Double
    let signals: [RecommendationSignal]
    let metadata: [String: String]
    let generatedAt: Date

    var headline: String {
        switch type {
        case .goingOutSuggestion:
            return metadata["headline"] ?? L10n.text("decision_good_message")
        case .outfitRecommendation:
            return metadata["headline"] ?? L10n.text("outfit_title_balanced")
        case .riskAlert:
            return metadata["headline"] ?? L10n.text("home_risk_label")
        }
    }

    var summary: String {
        signals.map(\.description).joined(separator: ". ")
    }
}

enum CandidateType: Equatable, Hashable, Sendable {
    case goingOutSuggestion
    case outfitRecommendation
    case riskAlert

    func hash(into hasher: inout Hasher) {
        switch self {
        case .goingOutSuggestion: hasher.combine("going_out")
        case .outfitRecommendation: hasher.combine("outfit")
        case .riskAlert: hasher.combine("risk")
        }
    }
}

struct RecommendationSignal: Equatable, Sendable {
    let kind: SignalKind
    let value: String
    let weight: Double

    var description: String {
        switch kind {
        case .temperature:
            return String(format: L10n.formatted("recommendation_signal_temp", value, metadata["range"] ?? ""))
        case .precipitation:
            return String(format: L10n.formatted("recommendation_signal_precip", value))
        case .wind:
            return String(format: L10n.formatted("recommendation_signal_wind", value))
        case .schedule:
            return L10n.text("recommendation_signal_schedule")
        case .activityMatch:
            return String(format: L10n.formatted("recommendation_signal_activity", value))
        case .uvIndex:
            return value
        case .riskAvoidance:
            return value
        }
    }

    var metadata: [String: String]
}

enum SignalKind: String, Equatable, Sendable {
    case temperature
    case precipitation
    case wind
    case schedule
    case activityMatch
    case uvIndex
    case riskAvoidance
}
