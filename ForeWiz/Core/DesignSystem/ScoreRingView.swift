import SwiftUI

/// Animated circular progress ring showing an outdoor-friendliness score.
/// Displays score as X/10 with modern design.
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
                .stroke(Color.white.opacity(0.06), lineWidth: resolvedLineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [scoreColor.opacity(0.5), scoreColor],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: resolvedLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: scoreColor.opacity(glowPulse ? 0.4 : 0.15), radius: glowPulse ? 6 : 3)
            VStack(spacing: 0) {
                Text(score.displayText)
                    .font(.system(size: size * 0.32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(score.subText)
                    .font(.system(size: size * 0.13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            animate(to: score.displayValue / 10)
            if !reduceMotion {
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

extension WeatherScore {
    var displayText: String {
        let value = displayValue
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    var subText: String {
        L10n.text("home_score_out_of_10")
    }
}
