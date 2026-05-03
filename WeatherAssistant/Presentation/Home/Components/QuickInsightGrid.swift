import SwiftUI

struct QuickInsightGrid: View {
    let recommendation: DailyRecommendation

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: AppSpacing.small)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.small) {
            MetricTile(
                icon: "figure.walk",
                title: "Dışarı skoru",
                value: scoreText,
                tint: AppTheme.color(for: recommendation.outdoorDecision)
            )

            MetricTile(
                icon: "clock.badge.checkmark",
                title: "Rahat aralık",
                value: recommendation.bestOutdoorWindow?.shortDisplayText ?? "Belirsiz",
                tint: AppTheme.accent
            )

            MetricTile(
                icon: "exclamationmark.triangle.fill",
                title: "Dikkat saati",
                value: recommendation.avoidWindows.first?.window.shortDisplayText ?? "Yok",
                tint: recommendation.avoidWindows.isEmpty ? AppTheme.success : AppTheme.warning
            )

            MetricTile(
                icon: "bell.badge.fill",
                title: "Akıllı uyarı",
                value: recommendation.risks.isEmpty ? "Gerek yok" : "Anlamlı risk var",
                tint: recommendation.risks.isEmpty ? AppTheme.success : AppTheme.danger
            )
        }
    }

    private var scoreText: String {
        recommendation.outdoorScore.displayValue.formatted(.number.precision(.fractionLength(1))) + "/10"
    }
}

private struct MetricTile: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        LiquidGlassContainer {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Image(systemName: icon)
                    .font(.headline)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.softBubbleGradient(tint: tint), in: Circle())
                    .foregroundStyle(tint)

                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(value)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .padding(AppSpacing.medium)
        }
        .accessibilityElement(children: .combine)
    }
}
