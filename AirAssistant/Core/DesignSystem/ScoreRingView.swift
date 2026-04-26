import SwiftUI

struct ScoreRingView: View {
    let score: WeatherScore

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.35), lineWidth: 10)
            Circle()
                .trim(from: 0, to: score.displayValue / 10)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(score.displayValue, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("/10")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 92, height: 92)
        .accessibilityLabel("Dışarı skoru \(score.displayValue, specifier: "%.1f") / 10")
    }

    private var scoreColor: Color {
        switch score.rawValue {
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
