import SwiftUI

struct DailyDecisionCard: View {
    let recommendation: DailyRecommendation

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Bugün dışarı çıkılır mı?")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    Text(recommendation.outdoorDecision.localizedTitle)
                        .font(AppTypography.largeTitle)
                    Text(recommendation.summaryText)
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)

                    if let bestWindow = recommendation.bestOutdoorWindow {
                        Label(bestWindow.shortDisplayText, systemImage: "clock.fill")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppTheme.accent)
                            .padding(.top, AppSpacing.small)
                    }
                }

                Spacer(minLength: AppSpacing.small)
                ScoreRingView(score: recommendation.outdoorScore)
            }
        }
    }
}
