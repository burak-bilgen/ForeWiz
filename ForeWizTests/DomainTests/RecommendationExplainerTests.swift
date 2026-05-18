import Testing
import Foundation
@testable import ForeWiz

@Suite("Recommendation Explainer Tests")
struct RecommendationExplainerTests {

    private let explainer = DefaultRecommendationExplainer()

    @Test("Temperature signal produces temperature explanation")
    func testTemperatureExplanation() {
        let candidate = RecommendationCandidate(
            id: UUID(),
            type: .outdoorWindow,
            score: 80,
            signals: [
                RecommendationSignal(kind: .temperature, value: "22°C", weight: 0.3, metadata: ["range": "good"])
            ],
            metadata: [:],
            generatedAt: Date()
        )
        let points = explainer.explain(candidate)
        #expect(!points.isEmpty)
        #expect(points.contains { $0.icon == "thermometer.medium" })
    }

    @Test("Precipitation signal produces warning tone")
    func testPrecipitationWarning() {
        let candidate = RecommendationCandidate(
            id: UUID(),
            type: .riskAlert,
            score: 60,
            signals: [
                RecommendationSignal(kind: .precipitation, value: "75%", weight: 0.5, metadata: [:])
            ],
            metadata: [:],
            generatedAt: Date()
        )
        let points = explainer.explain(candidate)
        #expect(points.contains { $0.tone == .warning })
        #expect(points.contains { $0.icon == "cloud.rain.fill" })
    }

    @Test("Multiple signals produce multiple points")
    func testMultipleSignals() {
        let candidate = RecommendationCandidate(
            id: UUID(),
            type: .activityWindow(.running),
            score: 85,
            signals: [
                RecommendationSignal(kind: .temperature, value: "18°C", weight: 0.3, metadata: ["range": "optimal"]),
                RecommendationSignal(kind: .schedule, value: "14:00-16:00", weight: 0.2, metadata: [:]),
                RecommendationSignal(kind: .activityMatch, value: "Running", weight: 0.4, metadata: [:])
            ],
            metadata: [:],
            generatedAt: Date()
        )
        let points = explainer.explain(candidate)
        #expect(points.count == 3)
    }

    @Test("Empty signals produce default explanation")
    func testEmptySignals() {
        let candidate = RecommendationCandidate(
            id: UUID(),
            type: .outdoorWindow,
            score: 50,
            signals: [],
            metadata: [:],
            generatedAt: Date()
        )
        let points = explainer.explain(candidate)
        #expect(!points.isEmpty)
        #expect(points.first?.icon == "info.circle")
    }

    @Test("Max 3 explanation points returned")
    func testMaxThreePoints() {
        let candidate = RecommendationCandidate(
            id: UUID(),
            type: .outdoorWindow,
            score: 80,
            signals: (0..<10).map { i in
                RecommendationSignal(kind: .temperature, value: "\(i)°C", weight: 0.3, metadata: ["range": "good"])
            },
            metadata: [:],
            generatedAt: Date()
        )
        let points = explainer.explain(candidate)
        #expect(points.count <= 3)
    }

    @Test("Activity match produces positive tone")
    func testActivityMatchPositive() {
        let candidate = RecommendationCandidate(
            id: UUID(),
            type: .activityWindow(.walking),
            score: 80,
            signals: [
                RecommendationSignal(kind: .activityMatch, value: "Walking", weight: 0.4, metadata: [:])
            ],
            metadata: [:],
            generatedAt: Date()
        )
        let points = explainer.explain(candidate)
        #expect(points.contains { $0.tone == .positive })
    }
}
