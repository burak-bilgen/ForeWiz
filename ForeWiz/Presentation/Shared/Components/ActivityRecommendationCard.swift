import SwiftUI
import WizPathKit

struct ActivityRecommendationCard: View {
    let recommendation: ActivityRecommendation

    var body: some View {
        LiquidGlassCard(accentColor: scoreColor, innerPadding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                header

                HStack(alignment: .center, spacing: 16) {
                    scoreRing
                    infoStack
                }

                reasonText
            }
        }
        .accessibilityElement(children: AccessibilityChildBehavior.combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var header: some View {
        HStack(spacing: 10) {
            GlassIcon(
                systemName: recommendation.activityType.iconName,
                color: scoreColor
            )

            Text(L10n.text(recommendation.activityType.localizedTitle))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.06), lineWidth: 6)

            Circle()
                .trim(from: 0, to: CGFloat(recommendation.score.rawValue) / 100)
                .stroke(
                    AngularGradient(
                        colors: [scoreColor.opacity(0.4), scoreColor],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: scoreColor.opacity(0.25), radius: 4)

            VStack(spacing: 1) {
                Text(recommendation.score.displayText)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(recommendation.score.subText)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(width: 64, height: 64)
    }

    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(recommendation.bestWindow.shortDisplayText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            } icon: {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(scoreColor)
            }

            Label {
                Text(recommendation.score.label)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            } icon: {
                Image(systemName: scoreIconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(scoreColor)
            }
        }
    }

    private var reasonText: some View {
        Text(recommendation.reason)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.55))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var scoreColor: Color {
        AppTheme.color(for: recommendation.score)
    }

    private var scoreIconName: String {
        switch recommendation.score.rawValue {
        case 80...100: "checkmark.circle.fill"
        case 60..<80: "cloud.sun.fill"
        case 40..<60: "exclamationmark.triangle.fill"
        default: "xmark.circle.fill"
        }
    }

    private var accessibilityLabel: String {
        let name = L10n.text(recommendation.activityType.localizedTitle)
        let score = recommendation.score.displayText
        let window = recommendation.bestWindow.shortDisplayText
        return "\(name): \(score) out of 10, best at \(window), \(recommendation.reason)"
    }
}

#Preview {
    ZStack {
        AppTheme.ambientGradient(for: .dark)
            .ignoresSafeArea()

        ActivityRecommendationCard(
            recommendation: ActivityRecommendation(
                activityType: .running,
                bestWindow: TimeWindow(
                    start: Date(),
                    end: Date().addingTimeInterval(7200)
                ),
                score: WeatherScore(rawValue: 85, label: L10n.text("decision_good")),
                reason: L10n.text("preview_activity_reason")
            )
        )
        .padding(.horizontal, 16)
    }
}
