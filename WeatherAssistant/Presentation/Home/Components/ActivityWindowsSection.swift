import SwiftUI

struct ActivityWindowsSection: View {
    let recommendations: [ActivityRecommendation]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label("Aktivite pencereleri", systemImage: "figure.run")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                if recommendations.isEmpty {
                    Text("Bugün aktiviteler için öne çıkan net bir aralık yok.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(recommendations) { recommendation in
                        ActivityWindowRow(recommendation: recommendation)
                    }
                }
            }
        }
    }
}

private struct ActivityWindowRow: View {
    let recommendation: ActivityRecommendation

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            Image(systemName: iconName)
                .font(.headline)
                .frame(width: 34, height: 34)
                .background(AppTheme.softBubbleGradient(tint: tint), in: Circle())
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(recommendation.activityType.localizedTitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)

                Text(recommendation.bestWindow.shortDisplayText)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(recommendation.reason)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Text(recommendation.score.displayValue.formatted(.number.precision(.fractionLength(1))))
                .font(AppTypography.headline)
                .foregroundStyle(tint)
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.xSmall)
                .background(tint.opacity(0.12), in: Capsule())
        }
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch recommendation.activityType {
        case .running:
            "figure.run"
        case .walking, .goingOutside:
            "figure.walk"
        case .cycling:
            "bicycle"
        }
    }

    private var tint: Color {
        switch recommendation.score.rawValue {
        case 80...100:
            AppTheme.success
        case 60..<80:
            AppTheme.accent
        case 40..<60:
            AppTheme.warning
        default:
            AppTheme.danger
        }
    }
}
