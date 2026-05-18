import Foundation

protocol RecommendationExplainer {
    func explain(_ candidate: RecommendationCandidate) -> [ExplanationPoint]
}

struct ExplanationPoint: Equatable, Sendable {
    let icon: String
    let text: String
    let tone: ExplanationTone

    enum ExplanationTone: String, Sendable {
        case positive
        case neutral
        case warning
    }
}

struct DefaultRecommendationExplainer: RecommendationExplainer {
    func explain(_ candidate: RecommendationCandidate) -> [ExplanationPoint] {
        var points: [ExplanationPoint] = []

        for signal in candidate.signals {
            switch signal.kind {
            case .temperature:
                let range = signal.metadata["range"] ?? ""
                points.append(ExplanationPoint(
                    icon: "thermometer.medium",
                    text: String(format: L10n.formatted("recommendation_explain_temp", signal.value, range)),
                    tone: scoreTone(signal.weight)
                ))

            case .precipitation:
                points.append(ExplanationPoint(
                    icon: "cloud.rain.fill",
                    text: String(format: L10n.formatted("recommendation_explain_precip", signal.value)),
                    tone: .warning
                ))

            case .wind:
                points.append(ExplanationPoint(
                    icon: "wind",
                    text: String(format: L10n.formatted("recommendation_explain_wind", signal.value)),
                    tone: scoreTone(signal.weight)
                ))

            case .schedule:
                points.append(ExplanationPoint(
                    icon: "clock.fill",
                    text: L10n.text("recommendation_explain_schedule"),
                    tone: .neutral
                ))

            case .activityMatch:
                points.append(ExplanationPoint(
                    icon: "figure.run",
                    text: String(format: L10n.formatted("recommendation_explain_activity", signal.value)),
                    tone: .positive
                ))

            case .uvIndex:
                points.append(ExplanationPoint(
                    icon: "sun.max.fill",
                    text: String(format: L10n.formatted("recommendation_explain_uv", signal.value)),
                    tone: .warning
                ))

            case .riskAvoidance:
                points.append(ExplanationPoint(
                    icon: "exclamationmark.triangle.fill",
                    text: signal.value,
                    tone: .warning
                ))
            }
        }

        if points.isEmpty {
            points.append(ExplanationPoint(
                icon: "info.circle",
                text: L10n.text("recommendation_explain_default"),
                tone: .neutral
            ))
        }

        return Array(points.prefix(3))
    }

    private func scoreTone(_ weight: Double) -> ExplanationPoint.ExplanationTone {
        switch weight {
        case 0.4...: return .positive
        case 0.2..<0.4: return .neutral
        default: return .warning
        }
    }
}
