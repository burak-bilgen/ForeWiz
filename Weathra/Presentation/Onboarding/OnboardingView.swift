import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false
    @State private var currentStep = 0
    @State private var appeared = false

    private let totalSteps = 3

    var body: some View {
        ZStack {
            OnboardingBackground(step: currentStep)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentStep)

            VStack(spacing: 0) {
                OnboardingProgressBar(current: currentStep, total: totalSteps)
                    .padding(.horizontal, 28)
                    .padding(.top, 20)

                Spacer()

                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(currentStep)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentStep)

                Spacer()

                bottomButton
                    .padding(.horizontal, 28)
                    .padding(.bottom, 48)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: HeroStep()
        case 1: FeaturesStep()
        case 2:
            PermissionsStep(
                viewModel: viewModel,
                appeared: appeared
            )
        default: EmptyView()
        }
    }

    // MARK: - Bottom button

    private var bottomButton: some View {
        Button {
            HapticManager.medium()
            advance()
        } label: {
            ZStack {
                if isCompleting {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Text(buttonLabel)
                            .font(.system(size: 17, weight: .semibold))
                        if currentStep < totalSteps - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(buttonBackground)
            }
            .shimmer(isActive: !isCompleting && !(isLastStep && !viewModel.canContinue))
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
        .disabled(isLastStep && !viewModel.canContinue || isCompleting)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canContinue)
    }

    private var buttonLabel: String {
        switch currentStep {
        case 0: L10n.text("onboarding_continue")
        case 1: L10n.text("onboarding_lets_start")
        default: L10n.text("onboarding_ready")
        }
    }

    private var buttonBackground: AnyShapeStyle {
        if isLastStep && !viewModel.canContinue {
            AnyShapeStyle(Color.gray.opacity(0.4))
        } else {
            AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.1, green: 0.35, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        }
    }

    private var isLastStep: Bool { currentStep == totalSteps - 1 }

    private func advance() {
        if currentStep < totalSteps - 1 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                currentStep += 1
            }
        } else {
            complete()
        }
    }

    private func complete() {
        guard viewModel.canContinue, !isCompleting else { return }
        isCompleting = true
        Task {
            do {
                try await onCompleted(viewModel.makeProfile(inheriting: existingProfile))
            } catch {
                viewModel.setErrorMessage(AppError.persistenceFailed.userMessage)
            }
            isCompleting = false
        }
    }
}

// MARK: - Background

private struct OnboardingBackground: View {
    let step: Int

    private var colors: (Color, Color, Color) {
        switch step {
        case 0:  return (Color(red: 0.25, green: 0.50, blue: 1.00), Color(red: 0.10, green: 0.30, blue: 0.85), Color(red: 0.50, green: 0.75, blue: 1.00))
        case 1:  return (Color(red: 0.30, green: 0.65, blue: 1.00), Color(red: 0.15, green: 0.55, blue: 0.85), Color(red: 0.20, green: 0.80, blue: 0.65))
        default: return (Color(red: 0.20, green: 0.45, blue: 0.90), Color(red: 0.40, green: 0.70, blue: 1.00), Color(red: 0.10, green: 0.60, blue: 0.85))
        }
    }

    var body: some View {
        AnimatedOrbBackground(primary: colors.0, secondary: colors.1, tertiary: colors.2)
            .animation(.easeInOut(duration: 0.8), value: step)
    }
}

// MARK: - Progress Bar

private struct OnboardingProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current
                        ? Color.white
                        : Color.white.opacity(0.22))
                    .frame(height: index == current ? 4 : 3)
                    .scaleEffect(x: index == current ? 1.4 : 1.0, anchor: .leading)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: current)
            }
        }
    }
}

// MARK: - Step 0: Hero

private struct HeroStep: View {
    @State private var iconScale: CGFloat = 0.4
    @State private var iconOpacity: Double = 0
    @State private var ringScale1: CGFloat = 0.6
    @State private var ringOpacity1: Double = 0
    @State private var ringScale2: CGFloat = 0.6
    @State private var ringOpacity2: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20

    private let sky = Color(red: 0.55, green: 0.82, blue: 1.0)

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(sky.opacity(0.10), lineWidth: 1.5)
                    .frame(width: 220, height: 220)
                    .scaleEffect(ringScale2)
                    .opacity(ringOpacity2)

                // Inner glow ring
                Circle()
                    .fill(sky.opacity(0.09))
                    .frame(width: 180, height: 180)
                    .scaleEffect(ringScale1)
                    .opacity(ringOpacity1)
                    .blur(radius: 12)

                // Core circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [sky.opacity(0.22), sky.opacity(0.04)],
                            center: .center, startRadius: 20, endRadius: 80
                        )
                    )
                    .frame(width: 150, height: 150)

                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 80))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(sky)
                    .shadow(color: sky.opacity(0.5), radius: 24, x: 0, y: 8)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .floating(amplitude: 8, duration: 3.5)
            }
            .padding(.bottom, 52)

            VStack(spacing: 16) {
                Text(L10n.text("onboarding_welcome"))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                Text(L10n.text("onboarding_subtitle"))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .opacity(titleOpacity)
            .offset(y: titleOffset)
        }
        .padding(.horizontal, 28)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.68).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.05)) {
                ringScale1 = 1.0
                ringOpacity1 = 1.0
            }
            withAnimation(.easeOut(duration: 0.9).delay(0.0)) {
                ringScale2 = 1.0
                ringOpacity2 = 1.0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.3)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
        }
    }
}

// MARK: - Step 1: Features

private struct FeaturesStep: View {
    private var features: [(icon: String, color: Color, title: String, subtitle: String)] {[
        ("brain.head.profile", Color(red: 0.4, green: 0.7, blue: 1.0), L10n.text("onboarding_feature_decision"), L10n.text("onboarding_feature_decision_desc")),
        ("figure.outdoor.cycle", Color(red: 0.4, green: 0.85, blue: 0.65), L10n.text("onboarding_feature_personal"), L10n.text("onboarding_feature_personal_desc")),
        ("tshirt.fill", Color(red: 0.8, green: 0.65, blue: 1.0), L10n.text("onboarding_comparison_what_wear"), L10n.text("onboarding_comparison_what_wear_weathra")),
        ("bell.badge.fill", Color(red: 1.0, green: 0.75, blue: 0.35), L10n.text("onboarding_feature_notifications"), L10n.text("onboarding_feature_notifications_desc")),
    ]}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("onboarding_why_weathra"))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(L10n.text("onboarding_why_subtitle"))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            .padding(.bottom, 36)
            .padding(.horizontal, 28)

            VStack(spacing: 14) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    FeatureRow(
                        icon: feature.icon,
                        accentColor: feature.color,
                        title: feature.title,
                        subtitle: feature.subtitle,
                        delay: Double(index) * 0.07
                    )
                }
            }
            .padding(.horizontal, 28)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let accentColor: Color
    let title: String
    let subtitle: String
    let delay: Double

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                appeared = true
            }
        }
    }
}

// MARK: - Step 2: Permissions

private struct PermissionsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let appeared: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("onboarding_permissions_title"))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(L10n.text("onboarding_permissions_subtitle"))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            .padding(.bottom, 36)
            .padding(.horizontal, 28)

            VStack(spacing: 14) {
                PermissionCard(
                    icon: "location.fill",
                    accentColor: Color(red: 0.4, green: 0.7, blue: 1.0),
                    title: L10n.text("onboarding_location_title"),
                    subtitle: L10n.text("onboarding_location_message"),
                    badge: locationBadge,
                    isGranted: viewModel.locationStatus == .authorized,
                    isRequired: true,
                    action: {
                        HapticManager.light()
                        viewModel.requestLocationPermission()
                    }
                )

                PermissionCard(
                    icon: "bell.badge.fill",
                    accentColor: Color(red: 1.0, green: 0.75, blue: 0.35),
                    title: L10n.text("onboarding_notification_title"),
                    subtitle: L10n.text("onboarding_notification_message"),
                    badge: notificationBadge,
                    isGranted: viewModel.notificationStatus == .authorized || viewModel.notificationStatus == .provisional,
                    isRequired: false,
                    action: {
                        HapticManager.light()
                        viewModel.requestNotificationPermission()
                    }
                )
            }
            .padding(.horizontal, 28)

            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.5))
                .padding(.horizontal, 28)
                .padding(.top, 16)
            }
        }
    }

    private var locationBadge: PermissionBadge {
        switch viewModel.locationStatus {
        case .authorized: .granted
        case .denied, .restricted: .denied
        case .notDetermined: .pending
        }
    }

    private var notificationBadge: PermissionBadge {
        switch viewModel.notificationStatus {
        case .authorized, .provisional: .granted
        case .denied: .denied
        case .notDetermined: .pending
        }
    }
}

private enum PermissionBadge {
    case pending, granted, denied
}

private struct PermissionCard: View {
    let icon: String
    let accentColor: Color
    let title: String
    let subtitle: String
    let badge: PermissionBadge
    let isGranted: Bool
    let isRequired: Bool
    let action: () -> Void

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    if isRequired {
                        Text(L10n.text("onboarding_location_required"))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.35))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Color(red: 1.0, green: 0.75, blue: 0.35).opacity(0.15),
                                in: Capsule()
                            )
                    }
                }
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .lineLimit(2)
            }

            Spacer()

            badgeView
        }
        .padding(16)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isGranted ? accentColor.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isGranted { action() }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(isRequired ? 0 : 0.1)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var badgeView: some View {
        switch badge {
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.6))
        case .denied:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
        case .pending:
            Text(L10n.text("onboarding_permission_allow"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Color.white.opacity(0.15),
                    in: Capsule()
                )
        }
    }
}
