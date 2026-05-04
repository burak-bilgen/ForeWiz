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
                title: String(localized: "widget_outdoor_score"),
                value: scoreText,
                note: outdoorDecisionNote,
                tint: AppTheme.color(for: recommendation.outdoorDecision)
            )

            MetricTile(
                icon: "clock.badge.checkmark",
                title: String(localized: "widget_best_time"),
                value: recommendation.bestOutdoorWindow?.shortDisplayText ?? String(localized: "forecast_no_best_window"),
                note: recommendation.bestOutdoorWindow == nil ? String(localized: "decision_moderate") : String(localized: "decision_good"),
                tint: AppTheme.accent
            )

            MetricTile(
                icon: "exclamationmark.triangle.fill",
                title: String(localized: "decision_risky"),
                value: avoidWindowText,
                note: avoidWindowNote,
                tint: recommendation.avoidWindows.isEmpty ? AppTheme.success : AppTheme.warning
            )

            MetricTile(
                icon: "bell.badge.fill",
                title: String(localized: "notification_uv"),
                value: notificationReasonText,
                note: notificationReasonNote,
                tint: recommendation.risks.isEmpty ? AppTheme.success : AppTheme.danger
            )
        }
    }

    private var scoreText: String {
        recommendation.outdoorScore.displayValue.formatted(.number.precision(.fractionLength(1))) + "/10"
    }

    private var outdoorDecisionNote: String {
        switch recommendation.outdoorDecision {
        case .good: String(localized: "decision_good")
        case .moderate: String(localized: "decision_moderate")
        case .risky: String(localized: "decision_risky")
        case .avoid: String(localized: "decision_avoid")
        }
    }

    private var avoidWindowText: String {
        guard let avoidWindow = recommendation.avoidWindows.first else {
            return String(localized: "risk_low")
        }

        return avoidWindow.window.shortDisplayText
    }

    private var avoidWindowNote: String {
        guard let avoidWindow = recommendation.avoidWindows.first else {
            return String(localized: "decision_good")
        }

        return avoidWindow.risk.title
    }

    private var notificationReasonText: String {
        guard let risk = recommendation.risks.first(where: { $0.severity >= .medium }) else {
            return String(localized: "risk_low")
        }

        return risk.title
    }

    private var notificationReasonNote: String {
        guard let risk = recommendation.risks.first(where: { $0.severity >= .medium }) else {
            return String(localized: "decision_good")
        }

        return risk.severity.localizedTitle
    }
}

private struct MetricTile: View {
    let icon: String
    let title: String
    let value: String
    let note: String
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

                Text(note)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(tint)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
            .padding(AppSpacing.medium)
        }
        .accessibilityElement(children: .combine)
    }
}
