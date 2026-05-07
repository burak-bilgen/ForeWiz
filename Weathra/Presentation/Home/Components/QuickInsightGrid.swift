import SwiftUI

/// 2×2 grid of compact glass tiles surfacing the most actionable numbers for the day.
struct QuickInsightGrid: View {
    let recommendation: DailyRecommendation

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.small),
        GridItem(.flexible(), spacing: AppSpacing.small)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.small) {
            MetricTile(
                icon: "figure.walk",
                title: L10n.text("widget_outdoor_score"),
                value: scoreText,
                note: recommendation.outdoorDecision.localizedTitle,
                tint: AppTheme.color(for: recommendation.outdoorDecision)
            )

            MetricTile(
                icon: "clock.badge.checkmark",
                title: L10n.text("widget_best_time"),
                value: recommendation.bestOutdoorWindow?.shortDisplayText
                    ?? L10n.text("forecast_no_best_window"),
                note: recommendation.bestOutdoorWindow == nil
                    ? L10n.text("decision_moderate")
                    : L10n.text("decision_good"),
                tint: AppTheme.accent
            )

            MetricTile(
                icon: "exclamationmark.triangle.fill",
                title: L10n.text("avoid_hours_title"),
                value: avoidWindowText,
                note: avoidWindowNote,
                tint: recommendation.avoidWindows.isEmpty ? AppTheme.success : AppTheme.warning
            )

            MetricTile(
                icon: "shield.lefthalf.filled",
                title: L10n.text("decision_risky"),
                value: notificationReasonText,
                note: notificationReasonNote,
                tint: recommendation.risks.isEmpty ? AppTheme.success : AppTheme.danger
            )
        }
    }

    private var scoreText: String {
        recommendation.outdoorScore.displayValue
            .formatted(.number.precision(.fractionLength(1))) + "/10"
    }

    private var avoidWindowText: String {
        recommendation.avoidWindows.first?.window.shortDisplayText
            ?? L10n.text("avoid_hours_none")
    }

    private var avoidWindowNote: String {
        recommendation.avoidWindows.first?.risk.title
            ?? L10n.text("decision_good")
    }

    private var notificationReasonText: String {
        recommendation.risks.first(where: { $0.severity >= .medium })?.title
            ?? L10n.text("risk_low")
    }

    private var notificationReasonNote: String {
        recommendation.risks.first(where: { $0.severity >= .medium })?.severity.localizedTitle
            ?? L10n.text("decision_good")
    }
}

/// Compact rectangular tile with an icon, title, primary value and tinted footnote.
struct MetricTile: View {
    let icon: String
    let title: String
    let value: String
    let note: String
    let tint: Color

    var body: some View {
        GlassCard(padding: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                ZStack {
                    Circle()
                        .fill(AppTheme.softBubble(tint))
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 32, height: 32)

                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(value)
                    .font(AppTypography.metricNumber)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                Text(note)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value), \(note)")
    }
}
