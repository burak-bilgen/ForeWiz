import SwiftUI

struct DailyDecisionCard: View {
    let recommendation: DailyRecommendation

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(spacing: AppSpacing.small) {
                    DecisionPill(decision: recommendation.outdoorDecision)
                    Spacer(minLength: AppSpacing.small)
                    Text(recommendation.outdoorScore.label)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AppSpacing.large) {
                        decisionText
                        Spacer(minLength: AppSpacing.small)
                        ScoreRingView(score: recommendation.outdoorScore)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        decisionText
                        ScoreRingView(score: recommendation.outdoorScore)
                    }
                }

                if let bestWindow = recommendation.bestOutdoorWindow {
                    Divider().opacity(0.4)
                    InsightRow(
                        icon: "clock.fill",
                        title: "Planı bu saate denk getir",
                        value: bestWindow.shortDisplayText,
                        tint: AppTheme.accent
                    )
                }
            }
        }
    }

    private var decisionText: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Bugünün dış plan kararı")
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.secondaryText)
            Text(recommendation.outdoorDecision.localizedTitle)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(recommendation.summaryText)
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct DecisionPill: View {
    let decision: OutdoorDecision

    var body: some View {
        Label(labelText, systemImage: iconName)
            .font(AppTypography.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xSmall)
            .background(AppTheme.color(for: decision).opacity(0.14), in: Capsule())
            .foregroundStyle(AppTheme.color(for: decision))
    }

    private var labelText: String {
        switch decision {
        case .good:
            "Rahat çıkılır"
        case .moderate:
            "Saat seç"
        case .risky:
            "Planı kısalt"
        case .avoid:
            "Ertele"
        }
    }

    private var iconName: String {
        switch decision {
        case .good:
            "checkmark.circle.fill"
        case .moderate:
            "info.circle.fill"
        case .risky:
            "exclamationmark.triangle.fill"
        case .avoid:
            "xmark.octagon.fill"
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 34, height: 34)
                .background(AppTheme.softBubbleGradient(tint: tint), in: Circle())
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(value)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
