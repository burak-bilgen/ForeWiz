import SwiftUI

// MARK: - Weather Feedback Card

/// A compact, dismissable card that lets users give quick feedback on the weather recommendation.
/// Feedback adjusts the user's temperature offset and wind sensitivity for future recommendations.
struct WeatherFeedbackCard: View {
    let onFeedback: (UserWeatherFeedback) async -> Void
    let onDismiss: () -> Void

    @State private var hasGivenFeedback = false
    @State private var selectedFeedback: UserWeatherFeedback?
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.liquidAccent.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: hasGivenFeedback ? "checkmark.circle.fill" : "hand.thumbsup.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(hasGivenFeedback ? .green : Color.liquidAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(hasGivenFeedback
                     ? L10n.text("feedback_thanks")
                     : L10n.text("feedback_question"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)

                Text(hasGivenFeedback
                     ? L10n.text("feedback_adjusted")
                     : L10n.text("feedback_subtitle"))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if !hasGivenFeedback {
                // Feedback buttons
                HStack(spacing: 6) {
                    feedbackButton(icon: "thermometer.snowflake", feedback: .tooCold, label: L10n.text("feedback_cold"))
                    feedbackButton(icon: "checkmark.circle", feedback: .justRight, label: L10n.text("feedback_just_right"))
                    feedbackButton(icon: "thermometer.sun.fill", feedback: .tooHot, label: L10n.text("feedback_hot"))
                }
            }

            // Dismiss button
            Button {
                withAnimation(AppTheme.pressSpring) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .opacity(hasGivenFeedback ? 0.6 : 1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.liquidAccent.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isAnimating ? 1 : 0.95)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(AppTheme.cardSpring.delay(0.1)) {
                isAnimating = true
            }
        }
    }

    private func feedbackButton(icon: String, feedback: UserWeatherFeedback, label: String) -> some View {
        Button {
            withAnimation(AppTheme.pressSpring) {
                selectedFeedback = feedback
                hasGivenFeedback = true
            }
            Task {
                await onFeedback(feedback)
            }
            HapticEngine.shared.selectionChanged()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundStyle(selectedFeedback == feedback ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(6)
            .background(
                selectedFeedback == feedback
                    ? Color.liquidAccent.opacity(0.2)
                    : Color.white.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(selectedFeedback == feedback ? Color.liquidAccent.opacity(0.3) : .white.opacity(0.05), lineWidth: 0.5)
            )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}


