import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false

    var body: some View {
        ZStack {
            AnimatedOrbBackground(
                primary: Color(red: 0.25, green: 0.48, blue: 0.92),
                secondary: Color(red: 0.15, green: 0.32, blue: 0.75),
                tertiary: Color(red: 0.40, green: 0.65, blue: 1.0)
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    heroSection
                        .padding(.top, 40)

                    welcomeCard
                    personalizationCard
                    permissionsCard

                    startButton
                        .padding(.vertical, 12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .dynamicTypeSize(.large ... .xxxLarge)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(red: 0.55, green: 0.82, blue: 1.0))
                .shadow(color: Color(red: 0.55, green: 0.82, blue: 1.0).opacity(0.35), radius: 20)

            Text(L10n.text("onboarding_welcome"))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(copy(
                tr: "Weathra artık sadece bir hava durumu uygulaması değil; kişisel hava asistanın. Abonelik, reklam ve widget gibi karmaşıklıkları kaldırdık. Sadece sana özel öneriler ve temiz bir deneyim.",
                en: "Weathra is no longer just a weather app; it's your personal weather assistant. We removed subscriptions, ads, widgets, and clutter. Just personalized guidance and a clean experience."
            ))
            .font(.system(size: 15))
            .foregroundStyle(Color.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
        }
    }

    // MARK: - Welcome Card

    private var welcomeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(copy(tr: "Neler değişti?", en: "What's new?"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 10) {
                    featureRow(icon: "sparkles", color: Color(red: 0.4, green: 0.72, blue: 1.0), text: copy(tr: "Abonelik ve reklam yok", en: "No subscriptions or ads"))
                    featureRow(icon: "checkmark.seal.fill", color: Color(red: 0.3, green: 0.85, blue: 0.58), text: copy(tr: "Sadece ana ekran ve ayarlar", en: "Just Home and Settings"))
                    featureRow(icon: "bell.badge.fill", color: Color(red: 1.0, green: 0.75, blue: 0.35), text: copy(tr: "Akıllı ve anlaşılır bildirimler", en: "Smart, clear notifications"))
                    featureRow(icon: "heart.text.square.fill", color: Color(red: 0.8, green: 0.65, blue: 1.0), text: copy(tr: "Profiline göre öneriler", en: "Recommendations tailored to you"))
                }
            }
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

    // MARK: - Personalization Card

    private var personalizationCard: some View {
        GlassCard(accentColor: Color(red: 1.0, green: 0.55, blue: 0.3)) {
            VStack(alignment: .leading, spacing: 16) {
                Label(copy(tr: "Sana göre ayarla", en: "Tune for you"), systemImage: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))

                VStack(alignment: .leading, spacing: 8) {
                    Text(copy(tr: "Sıcaklığı nasıl hissedersin?", en: "How do you feel temperature?"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                            let selected = viewModel.selectedSensitivity == sensitivity
                            Button {
                                HapticManager.selection()
                                viewModel.selectSensitivity(sensitivity)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: icon(for: sensitivity))
                                        .font(.system(size: 16))
                                    Text(sensitivity.localizedTitle)
                                        .font(.system(size: 11, weight: selected ? .semibold : .regular))
                                }
                                .foregroundStyle(selected ? Color(red: 1.0, green: 0.55, blue: 0.3) : Color.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    selected
                                        ? Color(red: 1.0, green: 0.55, blue: 0.3).opacity(0.12)
                                        : Color.white.opacity(0.05),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(selected ? Color(red: 1.0, green: 0.55, blue: 0.3).opacity(0.35) : Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(copy(tr: "Hangi aktiviteleri seversin?", en: "Which activities do you enjoy?"))
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
                                .foregroundStyle(selected ? Color(red: 0.3, green: 0.85, blue: 0.58) : Color.white.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selected
                                        ? Color(red: 0.3, green: 0.85, blue: 0.58).opacity(0.12)
                                        : Color.white.opacity(0.05),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule().stroke(
                                        selected ? Color(red: 0.3, green: 0.85, blue: 0.58).opacity(0.35) : Color.white.opacity(0.06),
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

    // MARK: - Permissions Card

    private var permissionsCard: some View {
        GlassCard(accentColor: Color(red: 0.4, green: 0.7, blue: 1.0)) {
            VStack(alignment: .leading, spacing: 16) {
                Label(copy(tr: "İzinler", en: "Permissions"), systemImage: "lock.shield.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))

                PermissionRow(
                    icon: "location.fill",
                    color: Color(red: 0.4, green: 0.7, blue: 1.0),
                    title: copy(tr: "Konum", en: "Location"),
                    subtitle: copy(tr: "Yerel hava tahmini için gerekli", en: "Required for local weather"),
                    isGranted: viewModel.locationStatus == .authorized,
                    isRequired: true
                ) {
                    viewModel.requestLocationPermission()
                }

                PermissionRow(
                    icon: "bell.badge.fill",
                    color: Color(red: 1.0, green: 0.75, blue: 0.35),
                    title: copy(tr: "Bildirimler", en: "Notifications"),
                    subtitle: copy(tr: "Zamanında hatırlatmalar için", en: "For timely reminders"),
                    isGranted: viewModel.notificationStatus == .authorized || viewModel.notificationStatus == .provisional,
                    isRequired: false
                ) {
                    viewModel.requestNotificationPermission()
                }
            }
        }
    }

    // MARK: - Start Button

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
                    Text(copy(tr: "Başla", en: "Get Started"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.1, green: 0.35, blue: 0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
        .disabled(isCompleting)
    }

    // MARK: - Helpers

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

    private func copy(tr: String, en: String) -> String {
        L10n.currentLanguageCode == "tr" ? tr : en
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
                            Text(copy(tr: "Gerekli", en: "Required"))
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
                    Text(copy(tr: "İzin Ver", en: "Allow"))
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

    private func copy(tr: String, en: String) -> String {
        L10n.currentLanguageCode == "tr" ? tr : en
    }
}
