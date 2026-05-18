import Foundation

protocol RecommendationRanker {
    func rank(
        _ candidates: [RecommendationCandidate],
        context: RecommendationContext
    ) -> [RecommendationCandidate]
}

struct RecommendationContext: Sendable {
    let timeOfDay: TimeOfDay
    let dayOfWeek: DayOfWeek
    let recentFeedback: [RecommendationFeedback]
    let lastShownTypes: Set<CandidateType>
    let isOffline: Bool

    enum TimeOfDay: String, Sendable {
        case earlyMorning = "early_morning"
        case morning = "morning"
        case midday = "midday"
        case afternoon = "afternoon"
        case evening = "evening"
        case night = "night"

        init(date: Date) {
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 5..<8: self = .earlyMorning
            case 8..<12: self = .morning
            case 12..<15: self = .midday
            case 15..<18: self = .afternoon
            case 18..<22: self = .evening
            default: self = .night
            }
        }
    }

    enum DayOfWeek: String, Sendable {
        case weekday
        case weekend

        init(date: Date) {
            let weekday = Calendar.current.component(.weekday, from: date)
            self = (weekday == 1 || weekday == 7) ? .weekend : .weekday
        }
    }
}

enum RecommendationFeedback: Equatable, Hashable, Codable, Sendable {
    case notRelevant(candidateId: UUID, timestamp: Date)
    case moreLikeThis(candidateId: UUID, timestamp: Date)
    case saved(candidateId: UUID, timestamp: Date)

    private enum CodingKeys: String, CodingKey {
        case type, candidateId, timestamp
    }

    private enum FeedbackType: String, Codable {
        case notRelevant, moreLikeThis, saved
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .notRelevant(let id, let ts):
            try container.encode(FeedbackType.notRelevant, forKey: .type)
            try container.encode(id, forKey: .candidateId)
            try container.encode(ts, forKey: .timestamp)
        case .moreLikeThis(let id, let ts):
            try container.encode(FeedbackType.moreLikeThis, forKey: .type)
            try container.encode(id, forKey: .candidateId)
            try container.encode(ts, forKey: .timestamp)
        case .saved(let id, let ts):
            try container.encode(FeedbackType.saved, forKey: .type)
            try container.encode(id, forKey: .candidateId)
            try container.encode(ts, forKey: .timestamp)
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(FeedbackType.self, forKey: .type)
        let id = try container.decode(UUID.self, forKey: .candidateId)
        let ts = try container.decode(Date.self, forKey: .timestamp)
        switch type {
        case .notRelevant: self = .notRelevant(candidateId: id, timestamp: ts)
        case .moreLikeThis: self = .moreLikeThis(candidateId: id, timestamp: ts)
        case .saved: self = .saved(candidateId: id, timestamp: ts)
        }
    }
}

struct ContextualRecommendationRanker: RecommendationRanker {
    private let maxResults: Int
    private let diversityThreshold: Double
    private let cooldownWindow: TimeInterval

    init(
        maxResults: Int = 5,
        diversityThreshold: Double = 0.6,
        cooldownWindow: TimeInterval = 3600
    ) {
        self.maxResults = maxResults
        self.diversityThreshold = diversityThreshold
        self.cooldownWindow = cooldownWindow
    }

    func rank(
        _ candidates: [RecommendationCandidate],
        context: RecommendationContext
    ) -> [RecommendationCandidate] {
        var scored = candidates.map { applyContextualBoost($0, context: context) }

        scored = applyDiversity(scored, threshold: diversityThreshold)
        scored = applyCooldown(scored, lastShown: context.lastShownTypes, window: cooldownWindow)
        scored = applyFeedbackPenalties(scored, feedback: context.recentFeedback)

        return Array(scored.sorted { $0.score > $1.score }.prefix(maxResults))
    }

    private func applyContextualBoost(
        _ candidate: RecommendationCandidate,
        context: RecommendationContext
    ) -> RecommendationCandidate {
        var adjustedScore = candidate.score

        switch candidate.type {
        case .activityWindow(let activity):
            if context.timeOfDay == .morning || context.timeOfDay == .midday {
                adjustedScore *= 1.15
            }
            if context.dayOfWeek == .weekend && activity == .goingOutside {
                adjustedScore *= 1.1
            }

        case .outdoorWindow:
            if context.timeOfDay == .afternoon || context.timeOfDay == .evening {
                adjustedScore *= 1.1
            }

        case .riskAlert:
            adjustedScore *= 1.3

        case .avoidWindow:
            if candidate.score > 30 {
                adjustedScore *= 1.2
            }

        case .outfitRecommendation:
            if context.timeOfDay == .earlyMorning || context.timeOfDay == .morning {
                adjustedScore *= 1.2
            }
        }

        if context.isOffline {
            adjustedScore *= 0.85
        }

        return RecommendationCandidate(
            id: candidate.id,
            type: candidate.type,
            score: adjustedScore,
            signals: candidate.signals,
            metadata: candidate.metadata,
            generatedAt: candidate.generatedAt
        )
    }

    private func applyDiversity(
        _ candidates: [RecommendationCandidate],
        threshold: Double
    ) -> [RecommendationCandidate] {
        var result: [RecommendationCandidate] = []
        var typeCounts: [CandidateType: Int] = [:]

        for candidate in candidates {
            let count = typeCounts[candidate.type, default: 0]
            if Double(count) / Double(max(1, result.count)) < threshold {
                result.append(candidate)
                typeCounts[candidate.type, default: 0] += 1
            }
        }

        return result.isEmpty ? candidates : result
    }

    private func applyCooldown(
        _ candidates: [RecommendationCandidate],
        lastShown: Set<CandidateType>,
        window: TimeInterval
    ) -> [RecommendationCandidate] {
        candidates.map { candidate in
            if lastShown.contains(candidate.type) {
                return RecommendationCandidate(
                    id: candidate.id,
                    type: candidate.type,
                    score: candidate.score * 0.7,
                    signals: candidate.signals,
                    metadata: candidate.metadata,
                    generatedAt: candidate.generatedAt
                )
            }
            return candidate
        }
    }

    private func applyFeedbackPenalties(
        _ candidates: [RecommendationCandidate],
        feedback: [RecommendationFeedback]
    ) -> [RecommendationCandidate] {
        let notRelevantIds = Set(feedback.compactMap {
            if case .notRelevant(let id, let timestamp) = $0,
               Date().timeIntervalSince(timestamp) < 86400 {
                return id
            }
            return nil
        })

        return candidates.map { candidate in
            if notRelevantIds.contains(candidate.id) {
                return RecommendationCandidate(
                    id: candidate.id,
                    type: candidate.type,
                    score: 0,
                    signals: candidate.signals,
                    metadata: candidate.metadata,
                    generatedAt: candidate.generatedAt
                )
            }
            return candidate
        }
    }
}
