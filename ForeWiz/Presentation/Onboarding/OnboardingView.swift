import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false
    @State private var currentStep = 0

    private let accentBlue = Color(red: 0.4, green: 0.72, blue: 1.0)
    private let accentGreen = Color(red: 0.3, green: 0.85, blue: 0.58)
    private let accentOrange = Color(red: 1.0, green: 0.55, blue: 0.3)
    private let accentPurple = Color(red: 0.65, green: 0.5, blue: 1.0)

    var body: some View {
        ZStack {
            AnimatedOrbBackground(
                primary: Color(red: 0.25, green: 0.48, blue: 0.92),
                secondary: Color(red: 0.15, green: 0.32, blue: 0.75),
                tertiary: Color(red: 0.40, green: 0.65, blue: 1.0)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                stepIndicator
                    .padding(.top, 32)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        Group {
                            switch currentStep {
                            case 0: introductionStep
                            case 1: comfortStep
                            case 2: permissionsStep
                            default: introductionStep
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                        if currentStep == 2 {
                            startButton
                                .padding(.top, 12)
                        } else {
                            nextButton
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .dynamicTypeSize(.large ... .xxxLarge)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? accentBlue : Color.white.opacity(0.2))
                    .frame(width: index == currentStep ? 20 : 8, height: 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Step 0: Introduction

    private var introductionStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accentBlue.opacity(0.18))
                        .frame(width: 90, height: 90)
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(accentBlue)
                }
                .shadow(color: accentBlue.opacity(0.3), radius: 20)

                Text(L10n.text("onboarding_welcome"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(L10n.text("onboarding_tagline"))
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }

            GlassCard(accentColor: accentBlue) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.text("onboarding_how_it_works"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    VStack(spacing: 10) {
                        featureRow(icon: "clock.fill", color: accentGreen, text: L10n.text("onboarding_feature_plan"))
                        featureRow(icon: "tshirt.fill", color: accentOrange, text: L10n.text("onboarding_feature_outfit"))
                        featureRow(icon: "bell.badge.fill", color: Color(red: 1.0, green: 0.45, blue: 0.45), text: L10n.text("onboarding_feature_alerts"))
                        featureRow(icon: "heart.text.square.fill", color: accentPurple, text: L10n.text("onboarding_feature_health"))
                    }
                }
            }
        }
    }

    // MARK: - Step 1: Comfort

    private var comfortStep: some View {
        VStack(spacing: 18) {
            stepTitle(
                icon: "thermometer.sun.fill",
                color: accentOrange,
                title: L10n.text("onboarding_comfort_title"),
                subtitle: L10n.text("onboarding_comfort_subtitle")
            )

            GlassCard(accentColor: accentOrange) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.text("how_do_you_feel"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                            let selected = viewModel.selectedSensitivity == sensitivity
                            Button {
                                HapticManager.selection()
                                viewModel.selectSensitivity(sensitivity)
                            } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: icon(for: sensitivity))
                                        .font(.system(size: 18))
                                    Text(sensitivity.localizedTitle)
                                        .font(.system(size: 11, weight: selected ? .semibold : .regular))
                                }
                                .foregroundStyle(selected ? accentOrange : Color.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    selected
                                        ? accentOrange.opacity(0.12)
                                        : Color.white.opacity(0.05),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(selected ? accentOrange.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            GlassCard(accentColor: accentBlue) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text("onboarding_wake_time"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    HStack {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(accentOrange)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { viewModel.wakeUpTime.hour ?? 7 },
                            set: { viewModel.setWakeUpHour($0) }
                        )) {
                            ForEach(5...11, id: \.self) { hour in
                                Text(String(format: "%02d:00", hour))
                                    .tag(hour)
                                    .foregroundStyle(.white)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                    }
                    .padding(.vertical, 2)
                }
            }

            GlassCard(accentColor: accentGreen) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text("which_activities_do_you"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    FlowLayout(spacing: 8) {
                        ForEach(ActivityType.allCases, id: \.self) { activity in
                            let selected = viewModel.preferredActivities.contains(activity)
                            Button {
                                HapticManager.selection()
                                viewModel.toggleActivity(activity)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: icon(for: activity))
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(activity.localizedTitle)
                                        .font(.system(size: 12, weight: selected ? .semibold : .regular))
                                }
                                .foregroundStyle(selected ? accentGreen : Color.white.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selected
                                        ? accentGreen.opacity(0.12)
                                        : Color.white.opacity(0.05),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule().stroke(
                                        selected ? accentGreen.opacity(0.35) : Color.white.opacity(0.06),
                                        lineWidth: 1
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Permissions

    private var permissionsStep: some View {
        VStack(spacing: 18) {
            stepTitle(
                icon: "lock.shield.fill",
                color: accentBlue,
                title: L10n.text("permissions"),
                subtitle: L10n.text("onboarding_permissions_subtitle")
            )

            GlassCard(accentColor: accentBlue, innerPadding: 10) {
                VStack(spacing: 0) {
                    PermissionRow(
                        icon: "location.fill",
                        color: accentBlue,
                        title: L10n.text("location"),
                        subtitle: L10n.text("required_for_local_weather"),
                        isGranted: viewModel.locationStatus == .authorized,
                        isRequired: true
                    ) {
                        viewModel.requestLocationPermission()
                    }

                    Divider().background(Color.white.opacity(0.06)).padding(.leading, 50)

                    PermissionRow(
                        icon: "bell.badge.fill",
                        color: accentOrange,
                        title: L10n.text("notifications"),
                        subtitle: L10n.text("for_timely_reminders"),
                        isGranted: viewModel.notificationStatus == .authorized || viewModel.notificationStatus == .provisional,
                        isRequired: false
                    ) {
                        viewModel.requestNotificationPermission()
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Navigation Buttons

    private var nextButton: some View {
        Button {
            HapticManager.light()
            withAnimation { currentStep += 1 }
        } label: {
            HStack(spacing: 8) {
                Text(L10n.text("continue_button"))
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.3, green: 0.55, blue: 1.0), Color(red: 0.15, green: 0.4, blue: 0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
        .padding(.top, 8)
    }

    private var startButton: some View {
        Button {
            HapticManager.medium()
            guard !isCompleting else { return }
            isCompleting = true
            Task {
                do {
                    try await onCompleted(viewModel.makeProfile(inheriting: existingProfile))
                } catch {
                    viewModel.setErrorMessage(AppError.persistenceFailed.userMessage)
                    isCompleting = false
                }
            }
        } label: {
            ZStack {
                if isCompleting {
                    PulsingDotsLoader(color: .white)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text(L10n.text("onboarding_activate"))
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [accentGreen, Color(red: 0.2, green: 0.6, blue: 0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
        .disabled(isCompleting)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func stepTitle(icon: String, color: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.14))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)
        }
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))
            Spacer()
        }
    }

    private func icon(for sensitivity: TemperatureSensitivity) -> String {
        switch sensitivity {
        case .getsColdEasily: return "snowflake"
        case .normal: return "thermometer.medium"
        case .getsHotEasily: return "sun.max.fill"
        }
    }

    private func icon(for activity: ActivityType) -> String {
        switch activity {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .goingOutside: return "sun.max.fill"
        }
    }
}

// MARK: - Permission Row

private struct PermissionRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let isGranted: Bool
    let isRequired: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        if isRequired {
                            Text(L10n.text("required"))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.15))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(red: 1.0, green: 0.55, blue: 0.15).opacity(0.12), in: Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.45))
                }

                Spacer()

                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(red: 0.3, green: 0.85, blue: 0.58))
                } else {
                    Text(L10n.text("allow"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isGranted ? color.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isGranted)
    }
}
