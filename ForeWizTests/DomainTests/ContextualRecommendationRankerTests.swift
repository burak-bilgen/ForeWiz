import Testing
import Foundation
@testable import ForeWiz

@Suite("Contextual Recommendation Ranker Tests")
struct ContextualRecommendationRankerTests {

    private let ranker = ContextualRecommendationRanker(maxResults: 5, diversityThreshold: 0.6, cooldownWindow: 3600)

    private func makeCandidate(type: CandidateType, score: Double = 50) -> RecommendationCandidate {
        RecommendationCandidate(
            id: UUID(),
            type: type,
            score: score,
            signals: [],
            metadata: [:],
            generatedAt: Date()
        )
    }

    @Test("Empty candidates returns empty")
    func testEmptyCandidates() {
        let context = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekday,
            recentFeedback: [],
            lastShownTypes: [],
            isOffline: false
        )
        let result = ranker.rank([], context: context)
        #expect(result.isEmpty)
    }

    @Test("Returns top candidates sorted by score")
    func testTopCandidatesSorted() {
        let c1 = makeCandidate(type: .goingOutSuggestion, score: 90)
        let c2 = makeCandidate(type: .riskAlert, score: 50)
        let c3 = makeCandidate(type: .goingOutSuggestion, score: 80)

        let context = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekday,
            recentFeedback: [],
            lastShownTypes: [],
            isOffline: false
        )
        let result = ranker.rank([c2, c3, c1], context: context)
        #expect(result.count <= 5)
        #expect(result.first?.score ?? 0 >= result.last?.score ?? 0)
    }

    @Test("Respects maxResults limit")
    func testMaxResults() {
        let candidates = (0..<10).map { makeCandidate(type: .goingOutSuggestion, score: Double($0 * 10)) }
        let context = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekday,
            recentFeedback: [],
            lastShownTypes: [],
            isOffline: false
        )
        let result = ranker.rank(candidates, context: context)
        #expect(result.count <= 5)
    }

    @Test("Offline context reduces scores")
    func testOfflinePenalty() {
        let c = makeCandidate(type: .goingOutSuggestion, score: 100)
        let online = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekday,
            recentFeedback: [],
            lastShownTypes: [],
            isOffline: false
        )
        let offline = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekday,
            recentFeedback: [],
            lastShownTypes: [],
            isOffline: true
        )
        let onlineResult = ranker.rank([c], context: online).first!
        let offlineResult = ranker.rank([c], context: offline).first!

        #expect(offlineResult.score < onlineResult.score)
    }

    @Test("Cooldown reduces score for recently shown types")
    func testCooldown() {
        let c = makeCandidate(type: .goingOutSuggestion, score: 80)
        let noCooldown = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekday,
            recentFeedback: [],
            lastShownTypes: [],
            isOffline: false
        )
        let withCooldown = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekday,
            recentFeedback: [],
            lastShownTypes: [.goingOutSuggestion],
            isOffline: false
        )
        let fresh = ranker.rank([c], context: noCooldown).first!
        let cooled = ranker.rank([c], context: withCooldown).first!

        #expect(cooled.score < fresh.score)
    }

    @Test("Not relevant feedback suppresses candidate")
    func testFeedbackSuppression() {
        let id = UUID()
        let candidate = RecommendationCandidate(
            id: id, type: .goingOutSuggestion, score: 80, signals: [], metadata: [:], generatedAt: Date()
        )
        let context = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekday,
            recentFeedback: [.notRelevant(candidateId: id, timestamp: Date())],
            lastShownTypes: [],
            isOffline: false
        )
        let result = ranker.rank([candidate], context: context)
        #expect(result.isEmpty || result.first?.score == 0)
    }

    @Test("Weekend boosts going out scores")
    func testWeekendBoost() {
        let outdoor = makeCandidate(type: .goingOutSuggestion, score: 70)
        let weekday = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekday,
            recentFeedback: [],
            lastShownTypes: [],
            isOffline: false
        )
        let weekend = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekend,
            recentFeedback: [],
            lastShownTypes: [],
            isOffline: false
        )
        let wd = ranker.rank([outdoor], context: weekday).first!
        let we = ranker.rank([outdoor], context: weekend).first!

        #expect(we.score > wd.score)
    }

    @Test("Risk alerts get priority boost")
    func testRiskBoost() throws {
        let risk = makeCandidate(type: .riskAlert, score: 50)
        let outdoor = makeCandidate(type: .goingOutSuggestion, score: 60)
        let context = RecommendationContext(
            timeOfDay: .morning,
            dayOfWeek: .weekday,
            recentFeedback: [],
            lastShownTypes: [],
            isOffline: false
        )
        let result = ranker.rank([outdoor, risk], context: context)
        let riskResult = result.first { $0.type == .riskAlert }
        #expect(riskResult != nil)
        let riskResultValue = try #require(riskResult)
        #expect(riskResultValue.score > 50)
    }
}
