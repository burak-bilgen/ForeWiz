import Foundation

protocol RecommendationStore {
    func loadLastCandidates() -> [RecommendationCandidate]
    func saveCandidates(_ candidates: [RecommendationCandidate])
    func recordFeedback(_ feedback: RecommendationFeedback)
    func recentFeedback() -> [RecommendationFeedback]
    func lastShownTypes() -> Set<CandidateType>
    func clear()
}

final class DefaultRecommendationStore: RecommendationStore {
    private let userDefaults: UserDefaults
    private let candidatesKey = "recommendation_candidates"
    private let feedbackKey = "recommendation_feedback"
    private let lastShownKey = "recommendation_last_shown"
    private let maxFeedbackHistory = 50
    private let feedbackExpiry: TimeInterval = 86400 * 3

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadLastCandidates() -> [RecommendationCandidate] {
        guard let data = userDefaults.data(forKey: candidatesKey),
              let candidates = try? JSONDecoder().decode([StoredCandidate].self, from: data) else {
            return []
        }
        return candidates.map { $0.toCandidate() }
    }

    func saveCandidates(_ candidates: [RecommendationCandidate]) {
        let stored = candidates.map { StoredCandidate(from: $0) }
        if let data = try? JSONEncoder().encode(stored) {
            userDefaults.set(data, forKey: candidatesKey)
        }

        let types = Set(candidates.map(\.type))
        if let data = try? JSONEncoder().encode(Array(types)) {
            userDefaults.set(data, forKey: lastShownKey)
        }
    }

    func recordFeedback(_ feedback: RecommendationFeedback) {
        var history = recentFeedback()
        history.append(feedback)

        let cutoff = Date().addingTimeInterval(-feedbackExpiry)
        history = history.filter { feedbackTimestamp($0) >= cutoff }

        if history.count > maxFeedbackHistory {
            history = Array(history.suffix(maxFeedbackHistory))
        }

        if let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: feedbackKey)
        }
    }

    func recentFeedback() -> [RecommendationFeedback] {
        guard let data = userDefaults.data(forKey: feedbackKey),
              let feedback = try? JSONDecoder().decode([RecommendationFeedback].self, from: data) else {
            return []
        }
        return feedback
    }

    func lastShownTypes() -> Set<CandidateType> {
        guard let data = userDefaults.data(forKey: lastShownKey),
              let types = try? JSONDecoder().decode([CandidateType].self, from: data) else {
            return []
        }
        return Set(types)
    }

    func clear() {
        userDefaults.removeObject(forKey: candidatesKey)
        userDefaults.removeObject(forKey: feedbackKey)
        userDefaults.removeObject(forKey: lastShownKey)
    }

    private func feedbackTimestamp(_ feedback: RecommendationFeedback) -> Date {
        switch feedback {
        case .notRelevant(_, let timestamp),
             .moreLikeThis(_, let timestamp),
             .saved(_, let timestamp):
            return timestamp
        }
    }
}

private struct StoredCandidate: Codable {
    let typeRaw: String
    let score: Double
    let metadata: [String: String]
    let generatedAt: Date

    init(from candidate: RecommendationCandidate) {
        self.typeRaw = candidate.type.rawValue
        self.score = candidate.score
        self.metadata = candidate.metadata
        self.generatedAt = candidate.generatedAt
    }

    func toCandidate() -> RecommendationCandidate {
        RecommendationCandidate(
            id: UUID(),
            type: CandidateType(rawValue: typeRaw),
            score: score,
            signals: [],
            metadata: metadata,
            generatedAt: generatedAt
        )
    }
}

extension CandidateType: Codable {
    var rawValue: String {
        switch self {
        case .goingOutSuggestion: return "going_out"
        case .outfitRecommendation: return "outfit"
        case .riskAlert: return "risk"
        }
    }

    init(rawValue: String) {
        switch rawValue {
        case "outfit": self = .outfitRecommendation
        case "risk": self = .riskAlert
        default: self = .goingOutSuggestion
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self.init(rawValue: raw)
    }
}
