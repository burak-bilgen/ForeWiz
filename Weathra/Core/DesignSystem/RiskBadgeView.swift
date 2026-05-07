import SwiftUI

/// Compact pill that surfaces a single weather risk with semantic colour and icon.
struct RiskBadgeView: View {
    let risk: WeatherRisk

    var body: some View {
        Label {
            Text(risk.title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        } icon: {
            Image(systemName: iconName)
        }
        .font(AppTypography.caption2)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.14), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous).stroke(color.opacity(0.18), lineWidth: 0.5)
        }
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
        case .pollen:
            "leaf.fill"
        case .airQuality:
            "aqi.medium"
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
