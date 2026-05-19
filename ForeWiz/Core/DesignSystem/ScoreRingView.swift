import SwiftUI

/// Animated circular progress ring showing an outdoor-friendliness score.
/// Adapts stroke width to size and respects reduce-motion.
struct ScoreRingView: View {
    let score: WeatherScore
    var size: CGFloat = 92
    var lineWidth: CGFloat?
    var showOutOf100: Bool = false

    @State private var progress: Double = 0
    @State private var glowPulse: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var resolvedLineWidth: CGFloat { lineWidth ?? max(6, size * 0.10) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: resolvedLineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [scoreColor.opacity(0.6), scoreColor],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: resolvedLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: scoreColor.opacity(glowPulse ? 0.55 : 0.25), radius: glowPulse ? 8 : 4)
            VStack(spacing: 1) {
                if showOutOf100 {
                    Text(String(format: "%.0f", score.displayValue))
                        .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text(L10n.text("home_score_out_of_100"))
                        .font(.system(size: size * 0.12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.4))
                } else {
                    Text(score.displayValue, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                    Text(L10n.text("home_score_out_of_10"))
                        .font(.system(size: size * 0.11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            animate(to: score.displayValue / 10)
            if !reduceMotion {
                // Single spring pulse on appear — no endless loop
                withAnimation(AppTheme.transitionSpring.delay(0.6)) {
                    glowPulse = true
                }
            }
        }
        .onChange(of: score) { _, new in animate(to: new.displayValue / 10) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(scoreAccessibilityLabel)
    }

    private func animate(to target: Double) {
        if reduceMotion {
            progress = target
        } else {
            withAnimation(.spring(response: 1.1, dampingFraction: 0.82).delay(0.15)) {
                progress = target
            }
        }
    }

    private var scoreAccessibilityLabel: String {
        let scoreValue = score.displayValue.formatted(.number.precision(.fractionLength(1)))
        return L10n.text("widget_outdoor_score") + " \(scoreValue) \(L10n.text("home_score_out_of_10"))"
    }

    private var scoreColor: Color {
        switch score.rawValue {
        case 80...100: AppTheme.success
        case 60..<80:  AppTheme.liquidAccent
        case 40..<60:  AppTheme.warning
        default:       AppTheme.danger
        }
    }
}
