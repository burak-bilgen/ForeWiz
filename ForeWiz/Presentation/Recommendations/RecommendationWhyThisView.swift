import SwiftUI

struct RecommendationWhyThisView: View {
    let explanationPoints: [ExplanationPoint]
    let onFeedback: (RecommendationFeedback) -> Void
    let candidateId: UUID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidOrbBackground(palette: .default)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Text(L10n.text("recommendation_why_title"))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 8)

                        ForEach(explanationPoints, id: \.text) { point in
                            ExplanationRow(point: point)
                        }

                        Divider()
                            .overlay(Color.white.opacity(0.1))
                            .padding(.vertical, 8)

                        Text(L10n.text("recommendation_explanation_title"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            FeedbackButton(
                                icon: "hand.thumbsdown",
                                label: L10n.text("recommendation_feedback_not_relevant")
                            ) {
                                onFeedback(.notRelevant(candidateId: candidateId, timestamp: Date()))
                                dismiss()
                            }

                            FeedbackButton(
                                icon: "hand.thumbsup",
                                label: L10n.text("recommendation_feedback_more_like")
                            ) {
                                onFeedback(.moreLikeThis(candidateId: candidateId, timestamp: Date()))
                                dismiss()
                            }

                            FeedbackButton(
                                icon: "bookmark",
                                label: L10n.text("recommendation_feedback_saved")
                            ) {
                                onFeedback(.saved(candidateId: candidateId, timestamp: Date()))
                                dismiss()
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("wizpath_done")) { dismiss() }
                        .foregroundStyle(Color.liquidAccent)
                }
            }
        }
    }
}

private struct ExplanationRow: View {
    let point: ExplanationPoint

    private var tintColor: Color {
        switch point.tone {
        case .positive: return .success
        case .neutral: return .liquidAccent
        case .warning: return .warning
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tintColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: point.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(tintColor)
            }

            Text(point.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)

            Spacer()
        }
        .padding(12)
        .background(.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FeedbackButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
