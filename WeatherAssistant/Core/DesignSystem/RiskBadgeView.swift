import SwiftUI

struct RiskBadgeView: View {
    let risk: WeatherRisk

    var body: some View {
        Label(risk.title, systemImage: iconName)
            .font(AppTypography.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xSmall)
            .background(color.opacity(0.14), in: Capsule())
            .foregroundStyle(color)
            .accessibilityLabel("\(risk.title), \(risk.severity.localizedTitle)")
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
        switch risk.severity {
        case .low:
            AppTheme.accent
        case .medium:
            AppTheme.warning
        case .high, .extreme:
            AppTheme.danger
        }
    }
}
