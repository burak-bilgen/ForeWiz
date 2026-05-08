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
        }
        .disabled(isLastStep && !viewModel.canContinue || isCompleting)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canContinue)
    }

    private var buttonLabel: String {
        switch currentStep {
        case 0: "Keşfet"
        case 1: "Başla"
        default: "Tamamla"
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

    private var topColor: Color {
        switch step {
        case 0: Color(red: 0.05, green: 0.08, blue: 0.18)
        case 1: Color(red: 0.04, green: 0.10, blue: 0.22)
        default: Color(red: 0.04, green: 0.12, blue: 0.20)
        }
    }

    private var bottomColor: Color {
        switch step {
        case 0: Color(red: 0.08, green: 0.14, blue: 0.30)
        case 1: Color(red: 0.06, green: 0.16, blue: 0.34)
        default: Color(red: 0.06, green: 0.18, blue: 0.30)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -80, y: -200)

            Circle()
                .fill(Color.cyan.opacity(0.08))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: 120, y: 180)
        }
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
                    .fill(index <= current ? Color.white : Color.white.opacity(0.25))
                    .frame(height: 3)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
            }
        }
    }
}

// MARK: - Step 0: Hero

private struct HeroStep: View {
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 200, height: 200)

                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 72))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color(red: 0.55, green: 0.8, blue: 1.0))
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
            }
            .padding(.bottom, 48)

            VStack(spacing: 16) {
                Text("Weathra")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Hava durumunu anlayan\nkişisel asistanın")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 28)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
        }
    }
}

// MARK: - Step 1: Features

private struct FeaturesStep: View {
    private let features: [(icon: String, color: Color, title: String, subtitle: String)] = [
        ("brain.head.profile", Color(red: 0.4, green: 0.7, blue: 1.0), "Akıllı Analiz", "Sadece sıcaklık değil, tüm hava koşullarını değerlendirir"),
        ("figure.outdoor.cycle", Color(red: 0.4, green: 0.85, blue: 0.65), "Aktivite Skorları", "Çıkmak, koşmak veya bisiklet için en iyi saati bulur"),
        ("tshirt.fill", Color(red: 0.8, green: 0.65, blue: 1.0), "Kıyafet Önerisi", "Günün havasına göre ne giymen gerektiğini söyler"),
        ("bell.badge.fill", Color(red: 1.0, green: 0.75, blue: 0.35), "Akıllı Bildirimler", "Hava değişmeden önce seni uyarır"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Neden Weathra?")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Diğer hava uygulamalarından farkı")
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
                Text("İzinler")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Sana özel deneyim için iki şeye ihtiyacımız var")
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
                        Text("Zorunlu")
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
            Text("İzin Ver")
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
