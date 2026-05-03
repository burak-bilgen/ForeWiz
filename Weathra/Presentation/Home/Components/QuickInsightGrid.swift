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
                title: "Dış plan kararı",
                value: scoreText,
                note: outdoorDecisionNote,
                tint: AppTheme.color(for: recommendation.outdoorDecision)
            )

            MetricTile(
                icon: "clock.badge.checkmark",
                title: "En rahat zaman",
                value: recommendation.bestOutdoorWindow?.shortDisplayText ?? "Net aralık yok",
                note: recommendation.bestOutdoorWindow == nil ? "Saatler birbirine yakın" : "Planı bu aralığa al",
                tint: AppTheme.accent
            )

            MetricTile(
                icon: "exclamationmark.triangle.fill",
                title: "Planı zorlayan saat",
                value: avoidWindowText,
                note: avoidWindowNote,
                tint: recommendation.avoidWindows.isEmpty ? AppTheme.success : AppTheme.warning
            )

            MetricTile(
                icon: "bell.badge.fill",
                title: "Bildirim nedeni",
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
        case .good:
            "Rahat çıkılır"
        case .moderate:
            "Saat seçmek önemli"
        case .risky:
            "Planı kısa tut"
        case .avoid:
            "Mümkünse ertele"
        }
    }

    private var avoidWindowText: String {
        guard let avoidWindow = recommendation.avoidWindows.first else {
            return "Özel kaçınma yok"
        }

        return avoidWindow.window.shortDisplayText
    }

    private var avoidWindowNote: String {
        guard let avoidWindow = recommendation.avoidWindows.first else {
            return "Gün geneli yönetilebilir"
        }

        return avoidWindow.risk.title
    }

    private var notificationReasonText: String {
        guard let risk = recommendation.risks.first(where: { $0.severity >= .medium }) else {
            return "Ek uyarı yok"
        }

        return risk.title
    }

    private var notificationReasonNote: String {
        guard let risk = recommendation.risks.first(where: { $0.severity >= .medium }) else {
            return "Planı değiştiren risk görünmüyor"
        }

        return risk.severity.localizedTitle + " öncelik"
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
