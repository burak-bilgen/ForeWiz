import Foundation

protocol WidgetRepository {
    func save(recommendation: DailyRecommendation) throws
}

final class SharedWidgetRepository: WidgetRepository {
    private let userDefaults: UserDefaults?
    private let key = "weathra_latest_recommendation"

    init(suiteName: String = "group.weathra") {
        self.userDefaults = UserDefaults(suiteName: suiteName)
    }

    func save(recommendation: DailyRecommendation) throws {
        guard let userDefaults else {
            throw AppError.persistenceFailed
        }

        let data = try JSONEncoder().encode(WidgetRecommendationPayload(recommendation: recommendation))
        userDefaults.set(data, forKey: key)
    }
}

private struct WidgetRecommendationPayload: Codable {
    let outdoorDecision: WidgetOutdoorDecisionPayload
    let outdoorScore: Int
    let bestOutdoorWindow: WidgetTimeWindowPayload?
    let summaryText: String

    init(recommendation: DailyRecommendation) {
        self.outdoorDecision = WidgetOutdoorDecisionPayload(decision: recommendation.outdoorDecision)
        self.outdoorScore = recommendation.outdoorScore.rawValue
        self.bestOutdoorWindow = recommendation.bestOutdoorWindow.map { WidgetTimeWindowPayload(timeWindow: $0) }
        self.summaryText = recommendation.summaryText
    }
}

private enum WidgetOutdoorDecisionPayload: String, Codable {
    case good
    case moderate
    case bad

    init(decision: OutdoorDecision) {
        switch decision {
        case .good:
            self = .good
        case .moderate:
            self = .moderate
        case .risky, .avoid:
            self = .bad
        }
    }
}

private struct WidgetTimeWindowPayload: Codable {
    let start: Date
    let end: Date

    init(timeWindow: TimeWindow) {
        self.start = timeWindow.start
        self.end = timeWindow.end
    }
}
