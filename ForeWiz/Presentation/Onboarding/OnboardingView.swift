import SwiftUI
import WizPathKit

// MARK: - Liquid Glass Onboarding
struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false
    @State private var pageAppeared = false
    @State private var showCitySearchSheet = false
    @State private var showHomePicker = false
    @State private var showWorkPicker = false

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

                    locationSetupSection
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
        .alert(L10n.text("tracking_settings_disabled_title"), isPresented: $viewModel.showTrackingSettingsAlert) {
            Button(L10n.text("action_open_settings")) {
                openSystemTrackingSettings()
            }
            Button(L10n.text("action_cancel"), role: .cancel) {
                viewModel.dismissTrackingSettingsAlert()
            }
        } message: {
            Text(L10n.text("tracking_settings_disabled_message"))
        }
        .sheet(isPresented: $showCitySearchSheet) {
            ModernAddLocationView { location in
                viewModel.addManualLocation(location)
            }
        }
        .onChange(of: viewModel.locationStatus) { old, new in
            if new == .authorized {
                HapticEngine.shared.success()
            } else if new == .denied || new == .restricted {
                HapticEngine.shared.warning()
            }
        }
        .onChange(of: viewModel.notificationStatus) { old, new in
            if new == .authorized || new == .provisional {
                HapticEngine.shared.success()
            }
        }
        .onChange(of: viewModel.trackingStatus) { old, new in
            if new == .granted {
                HapticEngine.shared.success()
            } else if new == .denied {
                HapticEngine.shared.warning()
            }
        }
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
                    isDenied: viewModel.locationStatus == .denied || viewModel.locationStatus == .restricted,
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
                    isDenied: false,
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
                    isDenied: viewModel.trackingStatus == .denied,
                    isRequired: false
                ) {
                    viewModel.requestTrackingPermission()
                }

                // Premium Tooltip Tracking Explanation
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.purple.opacity(0.8))
                        .padding(.top, 1)
                    
                    Text(L10n.text("permission_tracking_tooltip"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.purple.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.purple.opacity(0.12), lineWidth: 0.5)
                )
                .padding(.top, 4)
            }
        }
        .staggerEntrance(index: 4, appeared: pageAppeared)

        if viewModel.locationStatus == .denied || viewModel.locationStatus == .restricted {
            LiquidGlassCard(accentColor: AppTheme.ember, innerPadding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.ember.opacity(0.12))
                                .frame(width: 38, height: 38)
                            Image(systemName: "mappin.slash.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(AppTheme.ember)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.text("onboarding_fallback_city_title"))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(L10n.text("onboarding_fallback_city_subtitle"))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.55))
                                .lineLimit(3)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.06))

                    let chosenCities = viewModel.profile.savedLocations.filter { $0.id != "current-location" }
                    if let firstCity = chosenCities.first {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(AppTheme.success)
                            Text(firstCity.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            if !firstCity.address.isEmpty {
                                Text(verbatim: "(\(firstCity.address))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button {
                                HapticEngine.shared.medium()
                                showCitySearchSheet = true
                            } label: {
                                Text(L10n.text("action_change"))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.liquidAccent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.liquidAccent.opacity(0.1), in: Capsule())
                                    .overlay(Capsule().stroke(AppTheme.liquidAccent.opacity(0.25), lineWidth: 1))
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button {
                            HapticEngine.shared.medium()
                            showCitySearchSheet = true
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(L10n.text("onboarding_select_city_btn"))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(AppTheme.liquidAccent.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(AppTheme.liquidAccent.opacity(0.35), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle(scale: 0.98))
                    }
                }
            }
            .staggerEntrance(index: 5, appeared: pageAppeared)
        }

        if let error = viewModel.errorMessage {
            Text(error)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.coral)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Location Setup

    private var locationSetupSection: some View {
        LiquidGlassCard(accentColor: .liquidAccent, innerPadding: 14) {
            VStack(alignment: .leading, spacing: 14) {
                sectionLabel(icon: "mappin.and.ellipse", text: L10n.text("onboarding_location_step_title"))

                Text(L10n.text("onboarding_location_step_subtitle"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineSpacing(2)

                homeLocationRow
                workLocationRow
                commuteModeRow
            }
        }
        .staggerEntrance(index: 5, appeared: pageAppeared)
        .sheet(isPresented: $showHomePicker) {
            NavigationStack {
                ModernAddLocationView { location in
                    viewModel.setHomeLocation(location)
                }
            }
        }
        .sheet(isPresented: $showWorkPicker) {
            NavigationStack {
                ModernAddLocationView { location in
                    viewModel.setWorkLocation(location)
                }
            }
        }
    }

    @ViewBuilder
    private var homeLocationRow: some View {
        if let home = viewModel.homeLocation {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.liquidAccent.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: "house.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.liquidAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("location_home"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(home.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    HapticEngine.shared.medium()
                    viewModel.clearHomeLocation()
                } label: {
                    Text(L10n.text("action_clear"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ember)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.ember.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.ember.opacity(0.25), lineWidth: 1))
                }
            }
        } else {
            Button {
                HapticEngine.shared.medium()
                showHomePicker = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 38, height: 38)
                        Image(systemName: "house.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.text("onboarding_set_home_title"))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(L10n.text("action_skip"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.04), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                }
                .padding(10)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var workLocationRow: some View {
        if let work = viewModel.workLocation {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.liquidAccent.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.liquidAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("location_work"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(work.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    HapticEngine.shared.medium()
                    viewModel.clearWorkLocation()
                } label: {
                    Text(L10n.text("action_clear"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ember)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.ember.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.ember.opacity(0.25), lineWidth: 1))
                }
            }
        } else {
            Button {
                HapticEngine.shared.medium()
                showWorkPicker = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 38, height: 38)
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.text("onboarding_set_work_title"))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(L10n.text("action_skip"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.04), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                }
                .padding(10)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var commuteModeRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                Text(L10n.text("settings_commute_mode"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(TravelMode.allCases, id: \.self) { mode in
                    let selected = viewModel.commuteModeRaw == mode.rawValue
                    Button {
                        HapticEngine.shared.selectionChanged()
                        withAnimation(AppTheme.cardSpring) {
                            viewModel.setCommuteMode(mode)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: mode.iconName)
                                .font(.system(size: 16))
                            Text(L10n.text(mode.localizedKey))
                                .font(.system(size: 11, weight: selected ? .bold : .medium, design: .rounded))
                        }
                        .foregroundStyle(selected ? Color.liquidAccent : .white.opacity(0.45))
                        .frame(maxWidth: .infinity, minHeight: 48)
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

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            HapticEngine.shared.medium()
            guard !isCompleting else { return }
            isCompleting = true
            Task {
                do {
                    try await onCompleted(viewModel.makeProfile())
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
                Group {
                    if viewModel.canContinue {
                        AnyView(
                            LinearGradient(
                                colors: [AppTheme.liquidAccent, Color(hex: "#00D9FF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    } else {
                        AnyView(
                            Color.white.opacity(0.04)
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(viewModel.canContinue ? Color.white.opacity(0.25) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .pulseGlow(color: viewModel.canContinue ? AppTheme.liquidAccent : Color.clear, radius: 14)
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
        .disabled(isCompleting || !viewModel.canContinue)
        .opacity(viewModel.canContinue ? 1.0 : 0.5)
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

    private func openSystemTrackingSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Permission Row

private struct PermissionRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let isGranted: Bool
    var isDenied: Bool
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
                } else if isDenied {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                        Text(L10n.text("denied"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.ember)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.ember.opacity(0.1), in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.ember.opacity(0.25), lineWidth: 1))
                } else {
                    Text(L10n.text("onboarding_permission_btn"))
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
        .disabled(isGranted || isDenied)
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
