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
            .navigationTitle("Weathra kurulumu")
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
            PermissionSetupSection(viewModel: viewModel)
            PersonalizationSection(viewModel: viewModel)
            ContinueButton(
                isEnabled: viewModel.canContinue,
                isCompleting: isCompleting,
                action: complete
            )
        }
        .padding(.vertical, AppSpacing.small)
    }
}

private struct HeroSection: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("Planını havaya göre netleştir.")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Konumunu, sıcaklık algını ve dışarı çıkma alışkanlıklarını kullanarak bugün için anlaşılır bir karar üretiriz.")
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.medium)
        .background(AppTheme.weatherGradient(for: colorScheme), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 92, weight: .bold))
                .foregroundStyle(.white.opacity(0.10))
                .offset(x: 20, y: 24)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: AppTheme.accent.opacity(0.18), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
    }
}

private struct PermissionSetupSection: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                SectionHeader(
                    icon: "location.circle.fill",
                    title: "İzinler",
                    subtitle: "Konum tahmin için gerekli. Bildirimler isteğe bağlıdır; açarsan yalnızca önemli hava değişimleri için kullanılır."
                )

                CompactPermissionRow(
                    icon: "location.fill",
                    title: "Konum",
                    message: "Yakındaki tahmini hesaplamak için sadece kullanım sırasında istenir. Sürekli konum takibi yapılmaz.",
                    statusText: statusText(for: viewModel.locationStatus),
                    isRequired: true,
                    actionTitle: locationActionTitle,
                    action: requestOrOpenSettingsForLocation
                )

                CompactPermissionRow(
                    icon: "bell.badge.fill",
                    title: "Bildirim",
                    message: "Yağmur, sert rüzgar, yüksek UV veya iyi aktivite aralığı varsa günlük sınır içinde uyarır.",
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
            "Ayarlar"
        case .notDetermined:
            "İzin ver"
        }
    }

    private var notificationActionTitle: String {
        switch viewModel.notificationStatus {
        case .authorized, .provisional:
            "Açık"
        case .denied:
            "Ayarlar"
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

private struct PersonalizationSection: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                SectionHeader(
                    icon: "slider.horizontal.3",
                    title: "Konfor profili",
                    subtitle: "Skorlar sadece sıcaklığa bakmaz; senin soğuğa/sıcağa tepkini ve hangi aktiviteleri planladığını da hesaba katar."
                )

                Picker("Sıcaklık hissi", selection: Binding(
                    get: { viewModel.selectedSensitivity },
                    set: { viewModel.selectSensitivity($0) }
                )) {
                    ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                        Text(sensitivity.localizedTitle).tag(sensitivity)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Aktiviteler")
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
                        Text("Gerekli")
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
                Label(isEnabled ? "Weathra'yı başlat" : "Konum izni gerekli", systemImage: "arrow.right.circle.fill")
                    .font(AppTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.medium)
            .foregroundStyle(.white)
            .background(
                isEnabled ? AppTheme.weatherGradient(for: .light) : LinearGradient(colors: [.gray.opacity(0.45)], startPoint: .leading, endPoint: .trailing),
                in: Capsule()
            )
            .shadow(color: isEnabled ? AppTheme.accent.opacity(0.18) : .clear, radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(isEnabled == false || isCompleting)
    }
}
