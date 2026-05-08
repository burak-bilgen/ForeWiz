import Foundation
import os

protocol WidgetRepository {
    func save(recommendation: DailyRecommendation) throws
}

final class SharedWidgetRepository: WidgetRepository {
    private let userDefaults: UserDefaults?
    private let key = "weathra_latest_recommendation"
    private let logger = Logger(subsystem: "com.weathra.widget", category: "WidgetRepository")

    init(suiteName: String = "group.weathra") {
        self.userDefaults = UserDefaults(suiteName: suiteName)
        logger.info("Widget repository initialized with suite: \(suiteName)")
    }

    func save(recommendation: DailyRecommendation) throws {
        guard let userDefaults else {
            logger.error("UserDefaults is nil, cannot save widget data")
            throw AppError.persistenceFailed
        }

        do {
            let payload = WidgetRecommendationPayload(recommendation: recommendation)
            let data = try JSONEncoder().encode(payload)
            userDefaults.set(data, forKey: key)
            logger.info("Widget recommendation saved successfully")
        } catch {
            logger.error("Failed to encode widget recommendation: \(error.localizedDescription)")
            throw AppError.persistenceFailed
        }
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
