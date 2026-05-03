import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HeaderSection(saveMessage: viewModel.saveMessage)
                    AppearanceSection(profile: $viewModel.profile)
                    LanguageSection(profile: $viewModel.profile)
                    PermissionManagementSection()
                    PersonalPreferencesSection(profile: $viewModel.profile)
                    NotificationSettingsSection(profile: $viewModel.profile)
                }
                .padding(AppSpacing.medium)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.profile) {
            viewModel.save()
        }
    }
}

private struct HeaderSection: View {
    let saveMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text("Tercihler")
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(saveMessage ?? "Weathra kararlarını burada kişiselleştirirsin. Değişiklikler bu cihazda saklanır ve ana ekrandaki skorları etkiler.")
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct AppearanceSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        SettingsCard(
            icon: "circle.lefthalf.filled",
            title: "Görünüm",
            subtitle: "Sistem görünümünü takip edebilir ya da Weathra'yı sabit açık/koyu modda kullanabilirsin."
        ) {
            Picker("Tema", selection: $profile.appearance) {
                ForEach(AppAppearance.allCases, id: \.self) { appearance in
                    Text(appearance.localizedTitle).tag(appearance)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct LanguageSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        SettingsCard(
            icon: "globe",
            title: "Dil",
            subtitle: "Sistem diliyle devam edebilir ya da uygulama içi formatları seçtiğin dile göre kullanabilirsin."
        ) {
            Picker("Dil", selection: $profile.language) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.localizedTitle).tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct PermissionManagementSection: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        SettingsCard(
            icon: "hand.raised.fill",
            title: "İzinler",
            subtitle: "Onboarding'de verdiğin konum ve bildirim izinleri iOS tarafından yönetilir. Buradan sistem ayarlarına hızlıca geçebilirsin."
        ) {
            VStack(spacing: AppSpacing.small) {
                SettingsInfoRow(
                    icon: "location.fill",
                    title: "Konum",
                    value: "Yakındaki tahmin ve saatlik kararlar için kullanılır; arka planda takip edilmez."
                )

                SettingsInfoRow(
                    icon: "bell.badge.fill",
                    title: "Bildirimler",
                    value: "Yağmur, UV, rüzgar ve uygun aktivite aralıkları için günlük sınır içinde uyarı üretir."
                )

                Button(action: openSystemSettings) {
                    Label("iOS Ayarları'nı aç", systemImage: "arrow.up.forward.app.fill")
                        .font(AppTypography.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(url)
    }
}

private struct PersonalPreferencesSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        SettingsCard(
            icon: "person.crop.circle.badge.checkmark",
            title: "Konfor profili",
            subtitle: "Onboarding'deki kişisel seçimler burada kalır. Skorlar sıcaklık hissine ve seçili aktivitelere göre yeniden yorumlanır."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Picker("Birimler", selection: $profile.unitSystem) {
                    ForEach(UnitSystem.allCases, id: \.self) { system in
                        Text(system.localizedTitle).tag(system)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Sıcaklık hissi", selection: $profile.temperatureSensitivity) {
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
                            SettingsActivityChip(
                                activity: activity,
                                isSelected: profile.preferredActivities.contains(activity)
                            ) {
                                toggle(activity)
                            }
                        }
                    }
                }
            }
        }
    }

    private func toggle(_ activity: ActivityType) {
        if profile.preferredActivities.contains(activity) {
            profile.preferredActivities.remove(activity)
        } else {
            profile.preferredActivities.insert(activity)
        }

        if profile.preferredActivities.isEmpty {
            profile.preferredActivities.insert(.goingOutside)
        }
    }
}

private struct SettingsActivityChip: View {
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

private struct NotificationSettingsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        SettingsCard(
            icon: "bell.badge.fill",
            title: "Akıllı bildirimler",
            subtitle: "Bildirimler açık olsa bile Weathra her değişimde konuşmaz. Günlük üst sınır ve sessiz saatler bu gürültüyü kontrol eder."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Stepper(
                    "Günlük üst sınır: \(profile.maximumDailyNotifications)",
                    value: $profile.maximumDailyNotifications,
                    in: 1...3
                )
                .font(AppTypography.body)

                QuietHoursPicker(quietHours: $profile.quietHours)

                VStack(spacing: AppSpacing.small) {
                    ForEach($profile.notificationPreferences) { $preference in
                        NotificationPreferenceToggle(preference: $preference)
                    }
                }
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let content: Content

    init(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
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

                content
            }
        }
    }
}

private struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Text(value)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.small)
        .background(AppTheme.elevatedSurface.opacity(0.86), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
    }
}
