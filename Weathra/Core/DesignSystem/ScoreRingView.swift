import SwiftUI

/// Animated circular progress ring showing an outdoor-friendliness score.
/// Adapts stroke width to size and respects reduce-motion.
struct ScoreRingView: View {
    let score: WeatherScore
    var size: CGFloat = 92

    @State private var progress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var lineWidth: CGFloat { max(6, size * 0.10) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.separator.opacity(0.6), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(scoreColor.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(score.displayValue, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: size * 0.30, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("/10")
                    .font(.system(size: size * 0.13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(width: size, height: size)
        .onAppear { animate(to: score.displayValue / 10) }
        .onChange(of: score) { _, new in animate(to: new.displayValue / 10) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(scoreAccessibilityLabel)
    }

    private func animate(to target: Double) {
        if reduceMotion {
            progress = target
        } else {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) {
                progress = target
            }
        }
    }

    private var scoreAccessibilityLabel: String {
        let scoreValue = score.displayValue.formatted(.number.precision(.fractionLength(1)))
        return L10n.text("widget_outdoor_score") + " \(scoreValue) / 10"
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
