import SwiftUI
import UIKit

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let existingProfile: UserComfortProfile
    let onCompleted: (UserComfortProfile) async throws -> Void

    @State private var isCompleting = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    OnboardingContent(
                        viewModel: viewModel,
                        isCompleting: isCompleting,
                        complete: complete
                    )
                    .padding(AppSpacing.medium)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Başlangıç")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func complete() {
        guard viewModel.canContinue, isCompleting == false else {
            return
        }

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

private struct OnboardingContent: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let isCompleting: Bool
    let complete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HeroSection()
            OnboardingStepStrip()
            PermissionSetupSection(viewModel: viewModel)
            PersonalizationSection(viewModel: viewModel)
            ContinueButton(
                isEnabled: viewModel.canContinue,
                isCompleting: isCompleting,
                action: complete
            )
        }
        .padding(.vertical, AppSpacing.medium)
    }
}

private struct HeroSection: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Hava sana uysun.")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Konumuna göre canlı tahmin alır; dışarı çıkma, aktivite ve kıyafet kararını tek ekranda sadeleştirir.")
                        .font(AppTypography.body)
                        .foregroundStyle(.white.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.medium)

                Image(systemName: "cloud.sun.rain.fill")
                    .font(.system(size: 66, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.14), radius: 14, y: 8)
                    .accessibilityHidden(true)
            }

            FlowLayout(spacing: AppSpacing.small) {
                WeatherTrustPill(icon: "location.fill", title: "Canlı konum")
                WeatherTrustPill(icon: "cloud.sun.fill", title: "WeatherKit")
                WeatherTrustPill(icon: "bell.badge.fill", title: "Akıllı uyarı")
            }
        }
        .padding(AppSpacing.large)
        .background(AppTheme.weatherGradient(for: colorScheme), in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 150, weight: .bold))
                .foregroundStyle(.white.opacity(0.10))
                .offset(x: 24, y: 44)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: AppTheme.accent.opacity(0.22), radius: 26, y: 14)
        .accessibilityElement(children: .combine)
    }
}

private struct WeatherTrustPill: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(AppTypography.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xSmall)
            .background(.white.opacity(0.16), in: Capsule())
    }
}

private struct OnboardingStepStrip: View {
    private let steps = [
        ("Konum", "Yakındaki tahmin"),
        ("Profil", "Konfor ayarı"),
        ("Bildirim", "İsteğe bağlı")
    ]

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: AppSpacing.small) {
                    Text("\(index + 1)")
                        .font(AppTypography.caption.weight(.heavy))
                        .frame(width: 26, height: 26)
                        .background(AppTheme.accent.opacity(0.16), in: Circle())
                        .foregroundStyle(AppTheme.accent)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(step.0)
                            .font(AppTypography.caption.weight(.bold))
                            .foregroundStyle(AppTheme.ink)
                        Text(step.1)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.small)
                .background(AppTheme.surface.opacity(0.68), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
            }
        }
    }
}

private struct PermissionSetupSection: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Tahminin kaynağı")
                    .font(AppTypography.headline)
                Text("Hava verisi Apple WeatherKit üzerinden alınır. Konum yalnızca bulunduğun yerin tahminini istemek için kullanılır.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                PermissionActionRow(
                    icon: "location.fill",
                    title: "Konum",
                    message: "Yakındaki tahmini açmak için kullanım sırasında izin gerekir. Arka planda konum takibi yapılmaz.",
                    statusText: statusText(for: viewModel.locationStatus),
                    isRequired: true,
                    actionTitle: locationActionTitle,
                    action: requestOrOpenSettingsForLocation
                )

                PermissionActionRow(
                    icon: "bell.badge.fill",
                    title: "Akıllı bildirimler",
                    message: "Yağmur, UV veya iyi aktivite penceresi varsa günlük sınır içinde yerel uyarı planlanır.",
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
            "Açık"
        case .denied, .restricted:
            "Ayarları aç"
        case .notDetermined:
            "Konumu aç"
        }
    }

    private var notificationActionTitle: String {
        switch viewModel.notificationStatus {
        case .authorized, .provisional:
            "Açık"
        case .denied:
            "Ayarları aç"
        case .notDetermined:
            "İzin ver"
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
            "Bekliyor"
        case .authorized:
            "Açık"
        case .denied, .restricted:
            "Kapalı"
        }
    }

    private func notificationText(for status: NotificationAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            "İsteğe bağlı"
        case .authorized:
            "Açık"
        case .provisional:
            "Sessiz açık"
        case .denied:
            "Kapalı"
        }
    }
}

private struct PermissionActionRow: View {
    let icon: String
    let title: String
    let message: String
    let statusText: String
    let isRequired: Bool
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                Image(systemName: icon)
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.softBubbleGradient(tint: AppTheme.accent), in: RoundedRectangle(cornerRadius: AppTheme.iconBubbleRadius, style: .continuous))
                    .foregroundStyle(AppTheme.accent)

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    HStack(spacing: AppSpacing.xSmall) {
                        Text(title)
                            .font(AppTypography.headline)
                        if isRequired {
                            Text("Gerekli")
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.warning)
                        }
                    }

                    Text(message)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack {
                Text(statusText)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, AppSpacing.xSmall)
                    .background(AppTheme.elevatedSurface, in: Capsule())

                Spacer()

                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.small)
                        .background(AppTheme.weatherGradient(for: .light), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PersonalizationSection: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Konfor ayarın")
                    .font(AppTypography.headline)
                Text("Aynı hava herkese aynı hissettirmez. Skorları kendi sıcaklık algına ve aktivitelerine göre ayarlarız.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Sıcaklık hissin")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    VStack(spacing: AppSpacing.small) {
                        ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                            SensitivityRow(
                                sensitivity: sensitivity,
                                isSelected: viewModel.selectedSensitivity == sensitivity
                            ) {
                                viewModel.selectSensitivity(sensitivity)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Planladığın aktiviteler")
                        .font(AppTypography.caption)
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

private struct ContinueButton: View {
    let isEnabled: Bool
    let isCompleting: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isCompleting {
                    ProgressView()
                        .tint(.white)
                }
                Label(isEnabled ? "Tahmini hazırla" : "Konum izni gerekli", systemImage: "arrow.right.circle.fill")
                    .font(AppTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium)
            .foregroundStyle(.white)
            .background(
                isEnabled ? AppTheme.weatherGradient(for: .light) : LinearGradient(colors: [.gray.opacity(0.45)], startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .shadow(color: isEnabled ? AppTheme.accent.opacity(0.22) : .clear, radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(isEnabled == false || isCompleting)
    }
}

private struct SensitivityRow: View {
    let sensitivity: TemperatureSensitivity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: iconName)
                    .font(.headline)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.softBubbleGradient(tint: tint), in: Circle())
                    .foregroundStyle(tint)

                Text(sensitivity.localizedTitle)
                    .font(AppTypography.body)
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.success : .secondary)
            }
            .padding(AppSpacing.medium)
            .background(
                isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.elevatedSurface,
                in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var iconName: String {
        switch sensitivity {
        case .getsColdEasily:
            "snowflake"
        case .normal:
            "thermometer.medium"
        case .getsHotEasily:
            "sun.max.fill"
        }
    }

    private var tint: Color {
        switch sensitivity {
        case .getsColdEasily:
            AppTheme.accent
        case .normal:
            AppTheme.teal
        case .getsHotEasily:
            AppTheme.warning
        }
    }
}
