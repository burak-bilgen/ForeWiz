import SwiftUI

struct HourlyRecommendationRow: View {
    let recommendation: ActivityRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(recommendation.activityType.localizedTitle)
                .font(AppTypography.headline)
            Text(recommendation.bestWindow.shortDisplayText)
                .font(AppTypography.body)
            Text(recommendation.reason)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
    }
}
