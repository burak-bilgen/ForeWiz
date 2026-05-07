import SwiftUI
import UIKit

// MARK: - Page 1: Hero / value proposition

struct HeroPage: View {
    let logoNamespace: Namespace.ID
    let next: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Spacer().frame(height: AppSpacing.medium)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.10), radius: 12, y: 6)
                    .matchedGeometryEffect(id: "onboardingLogo", in: logoNamespace)
                    .accessibilityHidden(true)

                VStack(spacing: AppSpacing.xSmall) {
                    Text(L10n.text("onboarding_welcome"))
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.center)
                    Text(L10n.text("onboarding_subtitle"))
                        .font(AppTypography.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, AppSpacing.small)

                VStack(spacing: AppSpacing.small) {
                    OnboardingFeatureCard(
                        icon: "sparkles",
                        iconColor: AppTheme.sunshine,
                        title: L10n.text("onboarding_feature_decision"),
                        subtitle: L10n.text("onboarding_feature_decision_desc")
                    )
                    OnboardingFeatureCard(
                        icon: "heart.fill",
                        iconColor: AppTheme.teal,
                        title: L10n.text("onboarding_feature_personal"),
                        subtitle: L10n.text("onboarding_feature_personal_desc")
                    )
                    OnboardingFeatureCard(
                        icon: "bell.badge.fill",
                        iconColor: AppTheme.accent,
                        title: L10n.text("onboarding_feature_notifications"),
                        subtitle: L10n.text("onboarding_feature_notifications_desc")
                    )
                }

                PrimaryButton(
                    title: L10n.text("onboarding_continue"),
                    systemImage: "arrow.right"
                ) { next() }

                Spacer().frame(height: AppSpacing.xLarge)
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.top, AppSpacing.large)
        }
    }
}

private struct OnboardingFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                ZStack {
                    Circle()
                        .fill(AppTheme.softBubble(iconColor))
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Page 2: What makes us different

struct WhyWeathraPage: View {
    let logoNamespace: Namespace.ID
    let next: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Spacer().frame(height: AppSpacing.medium)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .matchedGeometryEffect(id: "onboardingLogo", in: logoNamespace)
                    .accessibilityHidden(true)

                VStack(spacing: AppSpacing.xSmall) {
                    Text(L10n.text("onboarding_why_weathra"))
                        .font(AppTypography.title)
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.center)
                    Text(L10n.text("onboarding_why_subtitle"))
                        .font(AppTypography.callout)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: AppSpacing.small) {
                    OnboardingComparisonCard(
                        title: L10n.text("onboarding_comparison_what_todo"),
                        otherIcon: "thermometer.medium",
                        otherText: L10n.text("onboarding_comparison_what_todo_other"),
                        weathraIcon: "checkmark.seal.fill",
                        weathraIconColor: AppTheme.success,
                        weathraText: L10n.text("onboarding_comparison_what_todo_weathra")
                    )
                    OnboardingComparisonCard(
                        title: L10n.text("onboarding_comparison_what_wear"),
                        otherIcon: "wind",
                        otherText: L10n.text("onboarding_comparison_what_wear_other"),
                        weathraIcon: "tshirt.fill",
                        weathraIconColor: AppTheme.sunshine,
                        weathraText: L10n.text("onboarding_comparison_what_wear_weathra")
                    )
                    OnboardingComparisonCard(
                        title: L10n.text("onboarding_comparison_best_time"),
                        otherIcon: "clock",
                        otherText: L10n.text("onboarding_comparison_best_time_other"),
                        weathraIcon: "clock.badge.checkmark.fill",
                        weathraIconColor: AppTheme.accent,
                        weathraText: L10n.text("onboarding_comparison_best_time_weathra")
                    )
                }

                PrimaryButton(
                    title: L10n.text("onboarding_lets_start"),
                    systemImage: "arrow.right"
                ) { next() }

                Spacer().frame(height: AppSpacing.xLarge)
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.top, AppSpacing.large)
        }
    }
}

private struct OnboardingComparisonCard: View {
    let title: String
    let otherIcon: String
    let otherText: String
    let weathraIcon: String
    let weathraIconColor: Color
    let weathraText: String

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(title)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(alignment: .top, spacing: AppSpacing.small) {
                    ComparisonSide(
                        icon: otherIcon,
                        iconColor: AppTheme.tertiaryText,
                        text: otherText,
                        isFaded: true
                    )
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.tertiaryText)
                        .frame(width: 24)
                        .padding(.top, 14)
                    ComparisonSide(
                        icon: weathraIcon,
                        iconColor: weathraIconColor,
                        text: weathraText,
                        isFaded: false
                    )
                }
            }
        }
    }
}

private struct ComparisonSide: View {
    let icon: String
    let iconColor: Color
    let text: String
    let isFaded: Bool

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.xSmall) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(height: 28)
            Text(text)
                .font(.caption)
                .foregroundStyle(isFaded ? AppTheme.secondaryText : AppTheme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.small)
        .background(
            (isFaded ? AppTheme.elevatedSurface.opacity(0.6) : iconColor.opacity(0.10)),
            in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
        )
    }
}

// MARK: - Page 3: Setup / permissions + preferences

struct SetupPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let isCompleting: Bool
    let complete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Spacer().frame(height: AppSpacing.medium)

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)

                VStack(spacing: AppSpacing.xSmall) {
                    Text(L10n.text("onboarding_setup_title"))
                        .font(AppTypography.title)
                        .foregroundStyle(AppTheme.ink)
                    Text(L10n.text("onboarding_setup_subtitle"))
                        .font(AppTypography.callout)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                PermissionSetupSection(viewModel: viewModel)
                PersonalizationSection(viewModel: viewModel)

                CompleteButton(
                    isEnabled: viewModel.canContinue,
                    isCompleting: isCompleting,
                    action: complete
                )

                Spacer().frame(height: AppSpacing.xLarge)
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.top, AppSpacing.large)
        }
    }
}

struct CompleteButton: View {
    let isEnabled: Bool
    let isCompleting: Bool
    let action: () -> Void

    var body: some View {
        PrimaryButton(
            title: isEnabled
                ? L10n.text("onboarding_ready")
                : L10n.text("onboarding_location_required"),
            systemImage: isEnabled ? "checkmark.circle.fill" : "location.slash.fill",
            isLoading: isCompleting,
            isEnabled: isEnabled,
            action: action
        )
    }
}

// MARK: - Confetti Overlay

struct ConfettiOverlay: View {
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let colors: [Color] = [
        AppTheme.accent,
        AppTheme.teal,
        AppTheme.sunshine,
        AppTheme.success,
        AppTheme.coral
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<24, id: \.self) { index in
                    let angle = Angle.degrees(Double(index) / 24 * 360)
                    let distance = Double.random(in: 110...geometry.size.width * 0.5)
                    let size = CGFloat.random(in: 6...10)
                    let color = colors[index % colors.count]

                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .offset(
                            x: isAnimating ? cos(angle.radians) * distance : 0,
                            y: isAnimating ? sin(angle.radians) * distance : 0
                        )
                        .scaleEffect(isAnimating ? 0 : 1)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.55)
                                .delay(Double.random(in: 0...0.20)),
                            value: isAnimating
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            if !reduceMotion { isAnimating = true }
        }
    }
}
