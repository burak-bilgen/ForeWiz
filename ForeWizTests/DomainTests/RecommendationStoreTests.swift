import Testing
import Foundation
@testable import ForeWiz

@Suite("Recommendation Store Tests")
struct RecommendationStoreTests {

    private func makeStore() -> DefaultRecommendationStore {
        let defaults = UserDefaults(suiteName: "test_recommendation_\(UUID().uuidString)")!
        defaults.removePersistentDomain(forName: defaults.suiteName!)
        return DefaultRecommendationStore(userDefaults: defaults)
    }

    @Test("Store returns empty when no data saved")
    func testEmptyStore() {
        let store = makeStore()
        #expect(store.loadLastCandidates().isEmpty)
        #expect(store.recentFeedback().isEmpty)
        #expect(store.lastShownTypes().isEmpty)
    }

    @Test("Candidates are saved and loaded")
    func testSaveAndLoadCandidates() {
        let store = makeStore()
        let candidates = [
            RecommendationCandidate(
                id: UUID(), type: .outdoorWindow, score: 85,
                signals: [], metadata: ["headline": "Great day"], generatedAt: Date()
            ),
            RecommendationCandidate(
                id: UUID(), type: .riskAlert, score: 60,
                signals: [], metadata: ["headline": "Rain alert"], generatedAt: Date()
            )
        ]
        store.saveCandidate(candidates)

        let loaded = store.loadLastCandidates()
        #expect(!loaded.isEmpty)
        #expect(loaded.first?.metadata["headline"] == "Great day")
    }

    @Test("Last shown types tracked correctly")
    func testLastShownTypes() {
        let store = makeStore()
        let candidates = [
            RecommendationCandidate(
                id: UUID(), type: .outdoorWindow, score: 80,
                signals: [], metadata: [:], generatedAt: Date()
            ),
            RecommendationCandidate(
                id: UUID(), type: .avoidWindow, score: 40,
                signals: [], metadata: [:], generatedAt: Date()
            )
        ]
        store.saveCandidate(candidates)

        let types = store.lastShownTypes()
        #expect(types.contains(.outdoorWindow))
        #expect(types.contains(.avoidWindow))
    }

    @Test("Feedback can be recorded and retrieved")
    func testFeedbackRecording() {
        let store = makeStore()
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
        let store = makeStore()
        store.saveCandidate([
            RecommendationCandidate(
                id: UUID(), type: .outdoorWindow, score: 80,
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
        let store = makeStore()
        for _ in 0..<5 {
            store.recordFeedback(.saved(candidateId: UUID(), timestamp: Date()))
        }
        #expect(store.recentFeedback().count == 5)
    }
}
