import Testing
import Foundation
@testable import ForeWiz

@Suite("Recommendation Store Tests")
struct RecommendationStoreTests {

    private func makeStore() -> DefaultRecommendationStore {
        DefaultRecommendationStore(userDefaults: .standard)
    }

    @Test("Store returns empty when no data saved")
    func testEmptyStore() {
        let store = DefaultRecommendationStore(userDefaults: createEphemeralDefaults())
        #expect(store.loadLastCandidates().isEmpty)
        #expect(store.recentFeedback().isEmpty)
        #expect(store.lastShownTypes().isEmpty)
    }

    @Test("Candidates are saved and loaded")
    func testSaveAndLoadCandidates() {
        let store = DefaultRecommendationStore(userDefaults: createEphemeralDefaults())
        let candidates = [
            RecommendationCandidate(
                id: UUID(), type: .goingOutSuggestion, score: 85,
                signals: [], metadata: ["headline": "Great day"], generatedAt: Date()
            ),
            RecommendationCandidate(
                id: UUID(), type: .riskAlert, score: 60,
                signals: [], metadata: ["headline": "Rain alert"], generatedAt: Date()
            )
        ]
        store.saveCandidates(candidates)

        let loaded = store.loadLastCandidates()
        #expect(!loaded.isEmpty)
        #expect(loaded.first?.metadata["headline"] == "Great day")
    }

    @Test("Last shown types tracked correctly")
    func testLastShownTypes() {
        let store = DefaultRecommendationStore(userDefaults: createEphemeralDefaults())
        let candidates = [
            RecommendationCandidate(
                id: UUID(), type: .goingOutSuggestion, score: 80,
                signals: [], metadata: [:], generatedAt: Date()
            ),
            RecommendationCandidate(
                id: UUID(), type: .riskAlert, score: 40,
                signals: [], metadata: [:], generatedAt: Date()
            )
        ]
        store.saveCandidates(candidates)

        let types = store.lastShownTypes()
        #expect(types.contains(.goingOutSuggestion))
        #expect(types.contains(.riskAlert))
    }

    @Test("Feedback can be recorded and retrieved")
    func testFeedbackRecording() {
        let store = DefaultRecommendationStore(userDefaults: createEphemeralDefaults())
        let id = UUID()
        let feedback = RecommendationFeedback.notRelevant(candidateId: id, timestamp: Date())

        store.recordFeedback(feedback)

        let history = store.recentFeedback()
        #expect(history.count == 1)
        if case .notRelevant(let recordedId, _) = history.first! {
            #expect(recordedId == id)
        } else {
            Issue.record("Expected notRelevant feedback")
        }
    }

    @Test("Clear removes all data")
    func testStoreClear() {
        let store = DefaultRecommendationStore(userDefaults: createEphemeralDefaults())
        store.saveCandidates([
            RecommendationCandidate(
                id: UUID(), type: .goingOutSuggestion, score: 80,
                signals: [], metadata: [:], generatedAt: Date()
            )
        ])
        store.recordFeedback(.moreLikeThis(candidateId: UUID(), timestamp: Date()))

        store.clear()

        #expect(store.loadLastCandidates().isEmpty)
        #expect(store.recentFeedback().isEmpty)
    }

    @Test("Multiple feedback records are stored")
    func testMultipleFeedback() {
        let store = DefaultRecommendationStore(userDefaults: createEphemeralDefaults())
        for _ in 0..<5 {
            store.recordFeedback(.saved(candidateId: UUID(), timestamp: Date()))
        }
        #expect(store.recentFeedback().count == 5)
    }

    private func createEphemeralDefaults() -> UserDefaults {
        let uniqueName = "test_recommendation_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: uniqueName)!
        defaults.removePersistentDomain(forName: uniqueName)
        return defaults
    }
}
