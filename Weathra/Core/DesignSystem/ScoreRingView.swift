import SwiftUI

private enum Constant {
    static let lineWidth: CGFloat = 10
}

struct ScoreRingView: View {
    let score: WeatherScore
    var size: CGFloat = 92
    @State private var progress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.12), lineWidth: Constant.lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: Constant.lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(score.displayValue, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                Text("/10")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8, blendDuration: 0)) {
                progress = score.displayValue / 10
            }
        }
        .onChange(of: score) {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8, blendDuration: 0)) {
                progress = score.displayValue / 10
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(scoreAccessibilityLabel)
    }

    private var scoreAccessibilityLabel: String {
        let scoreValue = score.displayValue.formatted(.number.precision(.fractionLength(1)))
        return String(localized: "widget_outdoor_score") + " \(scoreValue) / 10"
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
