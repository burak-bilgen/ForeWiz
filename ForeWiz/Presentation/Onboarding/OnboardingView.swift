import SwiftUI

// MARK: - Liquid Glass Onboarding
struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false
    @State private var pageAppeared = false

    var body: some View {
        ZStack {
            LiquidOrbBackground(palette: .clearSky)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    welcomeSection
                        .padding(.top, 48)

                    preferencesSection
                        .padding(.bottom, 8)

                    permissionsSection
                        .padding(.bottom, 8)

                    startButton
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
        .onAppear { animatePage() }
    }

    private func animatePage() {
        withAnimation(AppTheme.slowEaseOut) {
            pageAppeared = true
        }
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.liquidAccent.opacity(0.12))
                    .frame(width: 80, height: 80)
                    .blur(radius: 8)
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(width: 72, height: 72)
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.liquidAccent)
            }
            .floating(amplitude: 7, duration: 3.5)
            .staggerEntrance(index: 0, appeared: pageAppeared)

            Text(L10n.text("onboarding_welcome_title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .staggerEntrance(index: 1, appeared: pageAppeared)

            Text(L10n.text("onboarding_welcome_subtitle"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 16)
                .staggerEntrance(index: 2, appeared: pageAppeared)
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 14) {
            VStack(alignment: .leading, spacing: 14) {
                sectionLabel(icon: "globe", text: L10n.text("settings_language"))

                HStack(spacing: 8) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        let selected = viewModel.selectedLanguage == lang
                        Button {
                            HapticEngine.shared.selectionChanged()
                            withAnimation(AppTheme.cardSpring) {
                                viewModel.selectLanguage(lang)
                            }
                        } label: {
                            Text(lang.localizedTitle)
                                .font(.system(size: 14, weight: selected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(selected ? Color.liquidAccent : .white.opacity(0.45))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(
                                    selected
                                        ? Color.liquidAccent.opacity(0.12)
                                        : .white.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(selected ? Color.liquidAccent.opacity(0.35) : .white.opacity(0.06), lineWidth: 1)
                                )
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .staggerEntrance(index: 3, appeared: pageAppeared)
    }

    // MARK: - Permissions

    @ViewBuilder
    private var permissionsSection: some View {
        LiquidGlassCard(accentColor: AppTheme.liquidAccent, innerPadding: 14) {
            VStack(spacing: 10) {
                sectionLabel(icon: "lock.shield.fill", text: L10n.text("permissions"))

                PermissionRow(
                    icon: "location.fill",
                    color: AppTheme.liquidAccent,
                    title: L10n.text("location"),
                    subtitle: L10n.text("required_for_local_weather"),
                    isGranted: viewModel.locationStatus == .authorized,
                    isRequired: true
                ) {
                    viewModel.requestLocationPermission()
                }

                PermissionRow(
                    icon: "bell.badge.fill",
                    color: AppTheme.sunshine,
                    title: L10n.text("notifications"),
                    subtitle: L10n.text("for_timely_reminders"),
                    isGranted: viewModel.notificationStatus == .authorized || viewModel.notificationStatus == .provisional,
                    isRequired: false
                ) {
                    viewModel.requestNotificationPermission()
                }
                
                // Tracking permission for personalized ads
                PermissionRow(
                    icon: "hand.raised.fill",
                    color: .purple,
                    title: L10n.text("permission_tracking"),
                    subtitle: L10n.text("permission_tracking_subtitle"),
                    isGranted: viewModel.trackingStatus == .granted,
                    isRequired: false
                ) {
                    viewModel.requestTrackingPermission()
                }
            }
        }
        .staggerEntrance(index: 4, appeared: pageAppeared)

        if let error = viewModel.errorMessage {
            Text(error)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.coral)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            HapticEngine.shared.medium()
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
                    PulsingDotsLoader(color: .white, dotSize: 8)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                        Text(L10n.text("onboarding_activate"))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.liquidAccent.opacity(0.35), lineWidth: 1)
            )
            .pulseGlow(color: AppTheme.liquidAccent, radius: 14)
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
        .disabled(isCompleting)
        .staggerEntrance(index: 6, appeared: pageAppeared)
    }

    // MARK: - Helpers

    private func sectionLabel(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private func activityIcon(for activity: ActivityType) -> String {
        "sun.max.fill"
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
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        if isRequired {
                            Text(L10n.text("required"))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.ember)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.ember.opacity(0.12), in: Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.success)
                } else {
                    Text(L10n.text("allow"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
                }
            }
            .padding(12)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isGranted ? color.opacity(0.3) : .white.opacity(0.05), lineWidth: 1)
            )
        }
        .contentShape(Rectangle())

        .buttonStyle(.plain)
        .disabled(isGranted)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(
            locationRepository: MockLocationRepository(),
            notificationRepository: UserNotificationRepository()
        ),
        existingProfile: .default,
        onCompleted: { _ in }
    )
}
