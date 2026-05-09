import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false
    @State private var currentStep = 0
    @State private var languageKey = 0

    private let totalSteps = 4

    var body: some View {
        ZStack {
            OnboardingBackground(step: currentStep)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentStep)

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                TabView(selection: $currentStep) {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        stepView(for: step)
                            .tag(step)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentStep)

                navigationBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .dynamicTypeSize(.large ... .xxxLarge)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            if currentStep > 0 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1), in: Circle())
                }
            } else {
                Color.clear.frame(width: 36, height: 36)
            }

            Spacer()

            OnboardingProgressBar(current: currentStep, total: totalSteps)

            Spacer()

Button {
                withAnimation { currentStep = totalSteps - 1 }
            } label: {
                Text(copy(tr: "Atla", en: "Skip"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .opacity(currentStep < totalSteps - 1 ? 1 : 0)
            .disabled(currentStep >= totalSteps - 1)
        }
    }

    // MARK: - Step view

    @ViewBuilder
    private func stepView(for step: Int) -> some View {
        switch step {
        case 0: HeroStep()
        case 1: FeaturesStep()
        case 2:
            PersonalizationStep(viewModel: viewModel, languageKey: languageKey)
                .id(languageKey)
        case 3:
            PermissionsStep(viewModel: viewModel)
        default: EmptyView()
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        Button {
            HapticManager.medium()
            if currentStep < totalSteps - 1 {
                withAnimation { currentStep += 1 }
            } else {
                complete()
            }
        } label: {
            ZStack {
                if isCompleting {
                    PulsingDotsLoader(color: .white)
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
        case 2: L10n.text("onboarding_continue")
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

    private func copy(tr: String, en: String) -> String {
        L10n.currentLanguageCode == "tr" ? tr : en
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
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= current
                        ? Color.white
                        : Color.white.opacity(0.25))
                    .frame(height: 4)
                    .opacity(index <= current ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.3), value: current)
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
            Spacer(minLength: 20)

            ZStack {
                Circle()
                    .stroke(sky.opacity(0.10), lineWidth: 1.5)
                    .frame(width: 190, height: 190)
                    .scaleEffect(ringScale2)
                    .opacity(ringOpacity2)

                Circle()
                    .fill(sky.opacity(0.09))
                    .frame(width: 154, height: 154)
                    .scaleEffect(ringScale1)
                    .opacity(ringOpacity1)
                    .blur(radius: 12)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [sky.opacity(0.22), sky.opacity(0.04)],
                            center: .center, startRadius: 20, endRadius: 80
                        )
                    )
                    .frame(width: 128, height: 128)

                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 68))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(sky)
                    .shadow(color: sky.opacity(0.5), radius: 24, x: 0, y: 8)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .floating(amplitude: 8, duration: 3.5)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                Text(L10n.text("onboarding_welcome"))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.70)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                Text(L10n.text("onboarding_subtitle"))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                    Text(L10n.text("home_current_location"))
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color.white.opacity(0.45))
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .opacity(titleOpacity)
            .offset(y: titleOffset)

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 16)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.text("onboarding_why_weathra"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.80)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(L10n.text("onboarding_why_subtitle"))
                        .font(.system(size: 16))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }

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
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
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
                    .lineLimit(2)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)
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

// MARK: - Step 2: Personalization

private struct PersonalizationStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let languageKey: Int

    private let blue = Color(red: 0.4, green: 0.72, blue: 1.0)
    private let green = Color(red: 0.35, green: 0.85, blue: 0.62)
    private let amber = Color(red: 1.0, green: 0.72, blue: 0.32)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(copy(tr: "Asistanı kendine göre ayarla", en: "Tune the assistant for you"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(copy(
                        tr: "Bu seçimler skorları, kıyafet önerilerini ve bildirim önceliklerini doğrudan etkiler.",
                        en: "These choices directly shape scores, outfit guidance and notification priority."
                    ))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 14) {
                    OnboardingPersonalizationCard(
                        icon: "thermometer.sun.fill",
                        color: amber,
                        title: copy(tr: "Sıcaklığı nasıl hissedersin?", en: "How do you feel temperature?"),
                        subtitle: copy(tr: "Hissedilen sıcaklık skorunu kişiselleştirir.", en: "Personalizes the feels-like comfort score.")
                    ) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                            ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                                OnboardingOptionTile(
                                    icon: icon(for: sensitivity),
                                    title: sensitivity.localizedTitle,
                                    color: amber,
                                    isSelected: viewModel.selectedSensitivity == sensitivity
                                ) {
                                    HapticManager.selection()
                                    viewModel.selectSensitivity(sensitivity)
                                }
                            }
                        }
                    }

                    OnboardingPersonalizationCard(
                        icon: "figure.walk",
                        color: green,
                        title: copy(tr: "Dışarıda ne yaparsın?", en: "What do you do outside?"),
                        subtitle: copy(tr: "Ana ekran en iyi saatleri bu aktivitelere göre çıkarır.", en: "Home finds the best windows for these activities.")
                    ) {
                        FlowLayout(spacing: 8) {
                            ForEach(ActivityType.allCases, id: \.self) { activity in
                                OnboardingChip(
                                    icon: icon(for: activity),
                                    title: activity.localizedTitle,
                                    color: green,
                                    isSelected: viewModel.preferredActivities.contains(activity)
                                ) {
                                    HapticManager.selection()
                                    viewModel.toggleActivity(activity)
                                }
                            }
                        }
                    }

                    OnboardingPersonalizationCard(
                        icon: "heart.text.square.fill",
                        color: blue,
                        title: copy(tr: "Sağlık hassasiyetleri", en: "Health sensitivities"),
                        subtitle: copy(tr: "Polen ve hava kalitesi riskleri ana ekranda ve bildirimlerde öne çıkar.", en: "Pollen and air-quality risks are promoted on Home and in alerts.")
                    ) {
                        FlowLayout(spacing: 8) {
                            ForEach([AllergyType.pollen, .airQuality, .smoke, .dust], id: \.self) { allergy in
                                OnboardingChip(
                                    icon: allergy.icon,
                                    title: allergy.localizedTitle,
                                    color: blue,
                                    isSelected: viewModel.selectedAllergies.contains(allergy)
                                ) {
                                    HapticManager.selection()
                                    viewModel.toggleAllergy(allergy)
                                }
                            }
                        }

                        if viewModel.selectedAllergies.contains(.pollen) {
                            Divider().background(Color.white.opacity(0.08)).padding(.vertical, 8)
                            FlowLayout(spacing: 8) {
                                ForEach(PollenType.allCases, id: \.self) { pollenType in
                                    OnboardingChip(
                                        icon: "leaf.fill",
                                        title: pollenType.localizedTitle,
                                        color: amber,
                                        isSelected: viewModel.selectedPollenTypes.contains(pollenType)
                                    ) {
                                        HapticManager.selection()
                                        viewModel.togglePollenType(pollenType)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }

    private func icon(for sensitivity: TemperatureSensitivity) -> String {
        switch sensitivity {
        case .getsColdEasily:
            return "snowflake"
        case .normal:
            return "thermometer.medium"
        case .getsHotEasily:
            return "sun.max.fill"
        }
    }

    private func icon(for activity: ActivityType) -> String {
        switch activity {
        case .running:
            return "figure.run"
        case .walking:
            return "figure.walk"
        case .cycling:
            return "bicycle"
        case .goingOutside:
            return "sun.max.fill"
        }
    }

    private func copy(tr: String, en: String) -> String {
        L10n.currentLanguageCode == "tr" ? tr : en
    }
}

private struct OnboardingPersonalizationCard<Content: View>: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.16))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.44))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)
            }

            content()
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(color.opacity(0.12), lineWidth: 1))
    }
}

private struct OnboardingOptionTile: View {
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? color : Color.white.opacity(0.48))
            .frame(maxWidth: .infinity, minHeight: 76)
            .padding(.horizontal, 8)
            .background(
                isSelected ? color.opacity(0.15) : Color.white.opacity(0.055),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? color.opacity(0.36) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct OnboardingChip: View {
    let icon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? color : Color.white.opacity(0.52))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.15) : Color.white.opacity(0.055), in: Capsule())
            .overlay(Capsule().stroke(isSelected ? color.opacity(0.36) : Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Step 3: Permissions

private struct PermissionsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("onboarding_permissions_title"))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.80)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.text("onboarding_permissions_subtitle"))
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 28)

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

            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.5))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)
            }

            Spacer(minLength: 20)
        }
        .padding(.horizontal, 16)
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

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if isRequired {
                        Text("Required")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.35))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 1.0, green: 0.75, blue: 0.35).opacity(0.15), in: Capsule())
                    }
                }

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                badgeView
            }
            .layoutPriority(1)
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
    }

    @ViewBuilder
    private var badgeView: some View {
        switch badge {
        case .granted:
            Label(L10n.text("permission_open"), systemImage: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.6))
        case .denied:
            Label(L10n.text("permission_closed"), systemImage: "xmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
        case .pending:
            Text(L10n.text("onboarding_permission_allow"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15), in: Capsule())
        }
    }
}
