import SwiftUI
import UIKit

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false
    @State private var currentPage = 0
    @State private var showConfetti = false
    @Namespace private var logoNamespace
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                TabView(selection: $currentPage) {
                    HeroPage(
                        logoNamespace: logoNamespace,
                        next: { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 1 } }
                    )
                    .tag(0)

                    WhyWeathraPage(
                        logoNamespace: logoNamespace,
                        next: { withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { currentPage = 2 } }
                    )
                    .tag(1)

                    SetupPage(
                        viewModel: viewModel,
                        isCompleting: isCompleting,
                        complete: complete
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                if showConfetti {
                    ConfettiOverlay()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .navigationTitle(L10n.text( "onboarding_welcome"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func complete() {
        guard viewModel.canContinue, !isCompleting else {
            return
        }

        showConfetti = true
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

// MARK: - Page 1: Hero / Value Proposition

private struct HeroPage: View {
    let logoNamespace: Namespace.ID
    let next: () -> Void
    @State private var animateContent = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Spacer().frame(height: AppSpacing.medium)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .shadow(color: .black.opacity(0.18), radius: 16, y: 10)
                    .matchedGeometryEffect(id: "onboardingLogo", in: logoNamespace)
                    .accessibilityHidden(true)

                VStack(spacing: AppSpacing.xSmall) {
                    Text(L10n.text( "onboarding_welcome"))
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(L10n.text( "onboarding_subtitle"))
                        .font(AppTypography.body)
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, AppSpacing.small)

                VStack(spacing: AppSpacing.medium) {
                    FeatureCard(
                        icon: "sparkles",
                        iconColor: AppTheme.sunshine,
                        title: L10n.text( "onboarding_feature_decision"),
                        subtitle: L10n.text( "onboarding_feature_decision_desc"),
                        delay: 0
                    )
                    .offset(y: animateContent ? 0 : 40)
                    .opacity(animateContent ? 1 : 0)

                    FeatureCard(
                        icon: "heart.fill",
                        iconColor: AppTheme.teal,
                        title: L10n.text( "onboarding_feature_personal"),
                        subtitle: L10n.text( "onboarding_feature_personal_desc"),
                        delay: 0.1
                    )
                    .offset(y: animateContent ? 0 : 40)
                    .opacity(animateContent ? 1 : 0)

                    FeatureCard(
                        icon: "bell.badge.fill",
                        iconColor: AppTheme.accent,
                        title: L10n.text( "onboarding_feature_notifications"),
                        subtitle: L10n.text( "onboarding_feature_notifications_desc"),
                        delay: 0.2
                    )
                    .offset(y: animateContent ? 0 : 40)
                    .opacity(animateContent ? 1 : 0)
                }

                Button(action: next) {
                    HStack(spacing: AppSpacing.small) {
                        Text(L10n.text( "onboarding_continue"))
                            .font(AppTypography.headline)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.medium)
                    .foregroundStyle(.white)
                    .background(
                        AppTheme.weatherGradient(for: colorScheme),
                        in: Capsule()
                    )
                    .shadow(color: AppTheme.accent.opacity(0.22), radius: 16, y: 10)
                }
                .buttonStyle(.plain)
                .padding(.top, AppSpacing.small)

                Spacer().frame(height: AppSpacing.medium)
            }
            .padding(.horizontal, AppSpacing.large)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
        .onDisappear {
            animateContent = false
        }
    }
}

private struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var delay: Double = 0

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.medium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }
}

// MARK: - Page 2: What Makes Us Different

private struct WhyWeathraPage: View {
    let logoNamespace: Namespace.ID
    let next: () -> Void
    @State private var animateContent = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Spacer().frame(height: AppSpacing.medium)

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
                    .matchedGeometryEffect(id: "onboardingLogo", in: logoNamespace)
                    .accessibilityHidden(true)

                Text(L10n.text( "onboarding_why_weathra"))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(L10n.text( "onboarding_why_subtitle"))
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, AppSpacing.xSmall)

                VStack(spacing: AppSpacing.medium) {
                    ComparisonCard(
                        title: L10n.text( "onboarding_comparison_what_todo"),
                        otherIcon: "thermometer.medium",
                        otherText: L10n.text( "onboarding_comparison_what_todo_other"),
                        weathraIcon: "checkmark.seal.fill",
                        weathraIconColor: AppTheme.success,
                        weathraText: L10n.text( "onboarding_comparison_what_todo_weathra"),
                        delay: 0
                    )
                    .offset(y: animateContent ? 0 : 40)
                    .opacity(animateContent ? 1 : 0)

                    ComparisonCard(
                        title: L10n.text( "onboarding_comparison_what_wear"),
                        otherIcon: "wind",
                        otherText: L10n.text( "onboarding_comparison_what_wear_other"),
                        weathraIcon: "jacket.fill",
                        weathraIconColor: AppTheme.sunshine,
                        weathraText: L10n.text( "onboarding_comparison_what_wear_weathra"),
                        delay: 0.1
                    )
                    .offset(y: animateContent ? 0 : 40)
                    .opacity(animateContent ? 1 : 0)

                    ComparisonCard(
                        title: L10n.text( "onboarding_comparison_best_time"),
                        otherIcon: "clock",
                        otherText: L10n.text( "onboarding_comparison_best_time_other"),
                        weathraIcon: "clock.badge.checkmark.fill",
                        weathraIconColor: AppTheme.accent,
                        weathraText: L10n.text( "onboarding_comparison_best_time_weathra"),
                        delay: 0.2
                    )
                    .offset(y: animateContent ? 0 : 40)
                    .opacity(animateContent ? 1 : 0)
                }

                Button(action: next) {
                    HStack(spacing: AppSpacing.small) {
                        Text(L10n.text( "onboarding_lets_start"))
                            .font(AppTypography.headline)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.medium)
                    .foregroundStyle(.white)
                    .background(
                        AppTheme.weatherGradient(for: colorScheme),
                        in: Capsule()
                    )
                    .shadow(color: AppTheme.accent.opacity(0.22), radius: 16, y: 10)
                }
                .buttonStyle(.plain)
                .padding(.top, AppSpacing.xSmall)

                Spacer().frame(height: AppSpacing.medium)
            }
            .padding(.horizontal, AppSpacing.large)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
        .onDisappear {
            animateContent = false
        }
    }
}

private struct ComparisonCard: View {
    let title: String
    let otherIcon: String
    let otherText: String
    let weathraIcon: String
    let weathraIconColor: Color
    let weathraText: String
    var delay: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(AppTypography.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.leading, AppSpacing.xSmall)

            HStack(spacing: 0) {
                VStack(alignment: .center, spacing: AppSpacing.xSmall) {
                    Image(systemName: otherIcon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(height: 28)

                    Text(otherText)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.small)
                .padding(.horizontal, AppSpacing.small)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))

                VStack(spacing: AppSpacing.small) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(width: 28)

                VStack(alignment: .center, spacing: AppSpacing.xSmall) {
                    Image(systemName: weathraIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(weathraIconColor)
                        .frame(height: 28)

                    Text(weathraText)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.small)
                .padding(.horizontal, AppSpacing.small)
                .background(weathraIconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
            }
        }
        .padding(AppSpacing.medium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
    }
}

// MARK: - Page 3: Setup / Permissions + Preferences

private struct SetupPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let isCompleting: Bool
    let complete: () -> Void
    @State private var animateContent = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Spacer().frame(height: AppSpacing.medium)

                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.bottom, AppSpacing.xSmall)

                Text(L10n.text( "onboarding_setup_title"))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(L10n.text( "onboarding_setup_subtitle"))
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)

                VStack(spacing: AppSpacing.medium) {
                    PermissionSetupSection(viewModel: viewModel)
                        .offset(y: animateContent ? 0 : 50)
                        .opacity(animateContent ? 1 : 0)

                    PersonalizationSection(viewModel: viewModel)
                        .offset(y: animateContent ? 0 : 50)
                        .opacity(animateContent ? 1 : 0)
                }

                CompleteButton(
                    isEnabled: viewModel.canContinue,
                    isCompleting: isCompleting,
                    action: complete
                )
                .offset(y: animateContent ? 0 : 30)
                .opacity(animateContent ? 1 : 0)
                .padding(.top, AppSpacing.xSmall)

                Spacer().frame(height: AppSpacing.medium)
            }
            .padding(.horizontal, AppSpacing.large)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
        .onDisappear {
            animateContent = false
        }
    }
}

private struct CompleteButton: View {
    let isEnabled: Bool
    let isCompleting: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.small) {
                if isCompleting {
                    ProgressView()
                        .tint(.white)
                }
                Label(
                    isEnabled ? L10n.text( "onboarding_ready") : L10n.text( "onboarding_location_required"),
                    systemImage: isEnabled ? "party.popper.fill" : "location.slash.fill"
                )
                .font(AppTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium)
            .foregroundStyle(.white)
            .background(
                isEnabled
                    ? AppTheme.weatherGradient(for: colorScheme)
                    : LinearGradient(colors: [.gray.opacity(0.45)], startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .shadow(
                color: isEnabled ? AppTheme.accent.opacity(0.22) : .clear,
                radius: 18,
                y: 12
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isCompleting)
    }
}

// MARK: - Confetti Overlay

private struct ConfettiOverlay: View {
    @State private var isAnimating = false

    private let colors: [Color] = [
        AppTheme.accent,
        AppTheme.teal,
        AppTheme.sunshine,
        AppTheme.success,
        AppTheme.sky
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<30, id: \.self) { index in
                    let angle = Angle.degrees(Double(index) / 30 * 360)
                    let distance = Double.random(in: 120...geometry.size.width * 0.55)
                    let size = CGFloat.random(in: 5...11)
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
                            .spring(response: 0.55, dampingFraction: 0.5)
                                .delay(Double.random(in: 0...0.25)),
                            value: isAnimating
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Permission Setup Section

private struct PermissionSetupSection: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                SectionHeader(
                    icon: "location.circle.fill",
                    title: L10n.text( "onboarding_permissions_title"),
                    subtitle: L10n.text( "onboarding_permissions_subtitle")
                )

                CompactPermissionRow(
                    icon: "location.fill",
                    title: L10n.text( "onboarding_location_title"),
                    message: L10n.text( "onboarding_location_message"),
                    statusText: statusText(for: viewModel.locationStatus),
                    isRequired: true,
                    actionTitle: locationActionTitle,
                    action: requestOrOpenSettingsForLocation
                )

                CompactPermissionRow(
                    icon: "bell.badge.fill",
                    title: L10n.text( "onboarding_notification_title"),
                    message: L10n.text( "onboarding_notification_message"),
                    statusText: notificationText(for: viewModel.notificationStatus),
                    isRequired: false,
                    actionTitle: notificationActionTitle,
                    action: requestOrOpenSettingsForNotifications
                )

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var locationActionTitle: String {
        switch viewModel.locationStatus {
        case .authorized:
            L10n.text( "permission_open")
        case .denied, .restricted:
            L10n.text( "permission_settings")
        case .notDetermined:
            L10n.text( "permission_allow")
        }
    }

    private var notificationActionTitle: String {
        switch viewModel.notificationStatus {
        case .authorized, .provisional:
            L10n.text( "permission_open")
        case .denied:
            L10n.text( "permission_settings")
        case .notDetermined:
            L10n.text( "permission_allow")
        }
    }

    private func requestOrOpenSettingsForLocation() {
        if viewModel.locationStatus == .denied || viewModel.locationStatus == .restricted {
            openSettings()
        } else {
            viewModel.requestLocationPermission()
        }
    }

    private func requestOrOpenSettingsForNotifications() {
        if viewModel.notificationStatus == .denied {
            openSettings()
        } else {
            viewModel.requestNotificationPermission()
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        openURL(url)
    }

    private func statusText(for status: LocationAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            L10n.text( "permission_pending")
        case .authorized:
            L10n.text( "permission_open")
        case .denied, .restricted:
            L10n.text( "permission_closed")
        }
    }

    private func notificationText(for status: NotificationAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            L10n.text( "permission_optional")
        case .authorized:
            L10n.text( "permission_open")
        case .provisional:
            L10n.text( "permission_silent_on")
        case .denied:
            L10n.text( "permission_closed")
        }
    }
}

// MARK: - Personalization Section

private struct PersonalizationSection: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                SectionHeader(
                    icon: "slider.horizontal.3",
                    title: L10n.text( "onboarding_comfort_title"),
                    subtitle: L10n.text( "onboarding_comfort_subtitle")
                )

                Picker(L10n.text( "onboarding_temp_sensitivity"), selection: Binding(
                    get: { viewModel.selectedSensitivity },
                    set: { viewModel.selectSensitivity($0) }
                )) {
                    ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                        Text(sensitivity.localizedTitle).tag(sensitivity)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(L10n.text( "onboarding_activities"))
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)

                    FlowLayout(spacing: AppSpacing.small) {
                        ForEach(ActivityType.allCases, id: \.self) { activity in
                            ActivityChip(
                                activity: activity,
                                isSelected: viewModel.preferredActivities.contains(activity)
                            ) {
                                viewModel.toggleActivity(activity)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Shared Subviews

private struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 32, height: 32)
                .background(AppTheme.softBubbleGradient(tint: AppTheme.accent), in: RoundedRectangle(cornerRadius: AppTheme.iconBubbleRadius, style: .continuous))
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CompactPermissionRow: View {
    let icon: String
    let title: String
    let message: String
    let statusText: String
    let isRequired: Bool
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .frame(width: 28, height: 28)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xSmall) {
                    Text(title)
                        .font(AppTypography.caption.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    if isRequired {
                        Text(L10n.text( "permission_required"))
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.warning)
                    }
                    Text(statusText)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Text(message)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppSpacing.small)

            Button(action: action) {
                Text(actionTitle)
                    .font(AppTypography.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, AppSpacing.xSmall)
                    .background(AppTheme.accent.opacity(0.14), in: Capsule())
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.small)
        .background(AppTheme.elevatedSurface.opacity(0.86), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct ActivityChip: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(activity.localizedTitle, systemImage: iconName)
                .font(AppTypography.caption.weight(.semibold))
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.xSmall)
                .background(
                    isSelected ? AppTheme.accent.opacity(0.16) : AppTheme.elevatedSurface,
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.ink)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var iconName: String {
        switch activity {
        case .running:
            "figure.run"
        case .walking:
            "figure.walk"
        case .cycling:
            "bicycle"
        case .goingOutside:
            "sun.max.fill"
        }
    }
}
