import SwiftUI

struct AvoidHoursCard: View {
    let avoidWindows: [AvoidWindowRecommendation]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label("Bu Saatlerden Kaçın", systemImage: "exclamationmark.octagon.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                if avoidWindows.isEmpty {
                    Text("Bugün özellikle kaçınman gereken bir saat yok — gün boyunca rahatça dışarı çıkabilirsin.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(avoidWindows) { warning in
                        InsightRow(
                            icon: iconName(for: warning.risk.type),
                            title: "\(warning.window.shortDisplayText) · \(warning.risk.title)",
                            value: warning.reason,
                            tint: AppTheme.color(for: warning.severity)
                        )
                    }
                }
            }
        }
    }

    private func iconName(for riskType: WeatherRiskType) -> String {
        switch riskType {
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
}
