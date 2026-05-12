import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false
    @State private var pageAppeared = false
    private var accentOrange: Color { Color(red: 1.0, green: 0.55, blue: 0.3) }

    var body: some View {
        ZStack {
            AnimatedOrbBackground(
                primary: Color(red: 0.25, green: 0.48, blue: 0.92),
                secondary: Color(red: 0.15, green: 0.32, blue: 0.75),
                tertiary: Color(red: 0.40, green: 0.65, blue: 1.0)
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    welcomeSection
                        .padding(.top, 48)

                    preferencesSection
                        .padding(.bottom, 8)

                    permissionsSection
                        .padding(.bottom, 8)

                    startButton
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
        .onAppear { pageAppeared = true }
    }

    private var welcomeSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 72, height: 72)
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 34))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color(red: 0.4, green: 0.72, blue: 1.0))
            }
            .staggerEntrance(index: 0, appeared: pageAppeared)

            Text(L10n.text("onboarding_welcome_title"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .staggerEntrance(index: 1, appeared: pageAppeared)

            Text(L10n.text("onboarding_welcome_subtitle"))
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 16)
                .staggerEntrance(index: 2, appeared: pageAppeared)
        }
    }

    private var preferencesSection: some View {
        VStack(spacing: 12) {
            sectionCard {
                VStack(alignment: .leading, spacing: 14) {
                    sectionLabel(icon: "thermometer.sun.fill", title: L10n.text("how_do_you_feel"))

                    HStack(spacing: 8) {
                        ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                            let selected = viewModel.selectedSensitivity == sensitivity
                            Button {
                                HapticManager.selection()
                                viewModel.selectSensitivity(sensitivity)
                            } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: OnboardingView.icon(for: sensitivity))
                                        .font(.system(size: 18))
                                    Text(sensitivity.localizedTitle)
                                        .font(.system(size: 11, weight: selected ? .semibold : .regular))
                                }
                                .foregroundStyle(selected ? accentOrange : Color.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selected ? accentOrange.opacity(0.12) : Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(selected ? accentOrange.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1))
                            }
                            .accessibilityLabel(sensitivity.localizedTitle)
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            sectionCard {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel(icon: "sunrise.fill", title: L10n.text("onboarding_wake_time"))

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

            sectionCard {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel(icon: "figure.run", title: L10n.text("which_activities_do_you"))

                    FlowLayout(spacing: 8) {
                        ForEach(ActivityType.allCases, id: \.self) { activity in
                            let selected = viewModel.preferredActivities.contains(activity)
                            Button {
                                HapticManager.selection()
                                viewModel.toggleActivity(activity)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: OnboardingView.icon(for: activity))
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(activity.localizedTitle)
                                        .font(.system(size: 12, weight: selected ? .semibold : .regular))
                                }
                                .foregroundStyle(selected ? Color(red: 0.3, green: 0.85, blue: 0.58) : Color.white.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selected ? Color(red: 0.3, green: 0.85, blue: 0.58).opacity(0.12) : Color.white.opacity(0.05), in: Capsule())
                                .overlay(Capsule().stroke(selected ? Color(red: 0.3, green: 0.85, blue: 0.58).opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1))
                            }
                            .accessibilityLabel(activity.localizedTitle)
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var permissionsSection: some View {
        sectionCard {
            VStack(spacing: 10) {
                sectionLabel(icon: "lock.shield.fill", title: L10n.text("permissions"))

                PermissionRow(
                    icon: "location.fill",
                    color: Color(red: 0.4, green: 0.72, blue: 1.0),
                    title: L10n.text("location"),
                    subtitle: L10n.text("required_for_local_weather"),
                    isGranted: viewModel.locationStatus == .authorized,
                    isRequired: true
                ) {
                    viewModel.requestLocationPermission()
                }

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
                    colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.15, green: 0.4, blue: 0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
        .disabled(isCompleting)
    }

    private func sectionCard(@ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(16)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func sectionLabel(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
        }
    }

    private static func icon(for sensitivity: TemperatureSensitivity) -> String {
        switch sensitivity {
        case .getsColdEasily: return "snowflake"
        case .normal: return "thermometer.medium"
        case .getsHotEasily: return "sun.max.fill"
        }
    }

    private static func icon(for activity: ActivityType) -> String {
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
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isGranted ? color.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isGranted)
    }
}
