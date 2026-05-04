import SwiftUI

struct WeatherRiskSection: View {
    let risks: [WeatherRisk]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label(String(localized: "decision_risky"), systemImage: "exclamationmark.triangle.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                if risks.isEmpty {
                    Text(String(localized: "decision_good"))
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(spacing: AppSpacing.small) {
                        ForEach(risks) { risk in
                            WeatherRiskRow(risk: risk)
                        }
                    }
                }
            }
        }
    }
}

private struct WeatherRiskRow: View {
    let risk: WeatherRisk

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: iconName)
                .font(.headline)
                .frame(width: 34, height: 34)
                .background(AppTheme.softBubbleGradient(tint: color), in: Circle())
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xSmall) {
                    Text(risk.title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(risk.severity.localizedTitle)
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, AppSpacing.xSmall)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.12), in: Capsule())
                }

                Text(risk.message)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.small)
        .background(AppTheme.elevatedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch risk.type {
        case .heat:
            "thermometer.sun.fill"
        case .uv:
            "sun.max.fill"
        case .rain:
            "cloud.rain.fill"
        case .wind:
            "wind"
        case .humidity:
            "humidity.fill"
        case .cold:
            "snowflake"
        case .storm:
            "cloud.bolt.rain.fill"
        case .poorComfort:
            "exclamationmark.circle.fill"
        }
    }

    private var color: Color {
        AppTheme.color(for: risk.severity)
    }
}
