import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    let resetOnboarding: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HeaderSection(saveMessage: viewModel.saveMessage)
                    AppearanceSection(profile: $viewModel.profile)
                    PersonalPreferencesSection(profile: $viewModel.profile)
                    NotificationSettingsSection(profile: $viewModel.profile)
                    RoadmapSection()
                    ResetSection(resetOnboarding: resetOnboarding)
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
            Text("Uygulama tercihlerim")
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(saveMessage ?? "Tema, birimler, aktiviteler ve uyarı tercihleri bu cihazda saklanır.")
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
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label("Görünüm", systemImage: "paintpalette.fill")
                    .font(AppTypography.headline)

                Picker("Tema", selection: $profile.appearance) {
                    ForEach(AppAppearance.allCases, id: \.self) { appearance in
                        Text(appearance.localizedTitle).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Vurgu rengi")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)

                    HStack(spacing: AppSpacing.small) {
                        ForEach(AppAccentPalette.allCases, id: \.self) { palette in
                            AccentSwatch(
                                palette: palette,
                                isSelected: profile.accentPalette == palette
                            ) {
                                profile.accentPalette = palette
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct AccentSwatch: View {
    let palette: AppAccentPalette
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xSmall) {
                Circle()
                    .fill(AppTheme.accent(for: palette))
                    .frame(width: 34, height: 34)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }

                Text(palette.localizedTitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.small)
            .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct PersonalPreferencesSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label("Konfor profili", systemImage: "person.crop.circle.badge.checkmark")
                    .font(AppTypography.headline)

                Picker("Birimler", selection: $profile.unitSystem) {
                    ForEach(UnitSystem.allCases, id: \.self) { system in
                        Text(system.localizedTitle).tag(system)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Sıcaklık hassasiyeti", selection: $profile.temperatureSensitivity) {
                    ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                        Text(sensitivity.localizedTitle).tag(sensitivity)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Aktiviteler")
                        .font(AppTypography.caption)
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
    }
}

private struct SettingsActivityChip: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(activity.localizedTitle)
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
}

private struct NotificationSettingsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label("Akıllı bildirimler", systemImage: "bell.badge.fill")
                    .font(AppTypography.headline)

                Stepper(
                    "Günlük üst sınır: \(profile.maximumDailyNotifications)",
                    value: $profile.maximumDailyNotifications,
                    in: 1...3
                )

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

private struct RoadmapSection: View {
    private let features = [
        ("Widget", "Kilit ekranında sıcaklık, skor ve rahat aralık"),
        ("Yağış çizelgesi", "Saatlik yağmur ihtimali ve miktarı tek satırda"),
        ("Favori konumlar", "Ev, iş ve seyahat yerleri arasında hızlı geçiş"),
        ("Hava kalitesi", "AQI, polen ve UV ile daha gerçekçi konfor skoru"),
        ("Harita/radar", "Yağış ve rüzgar katmanlarıyla yakın takip"),
        ("Apple Watch", "Bilekte skor, risk ve bildirim komplikasyonu"),
        ("Takvim", "Planlara göre en iyi dışarı çıkma zamanı"),
        ("Sağlık", "Koşu/yürüyüş alışkanlığına göre aktivite önerisi")
    ]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label("Geliştirme rotası", systemImage: "sparkles")
                    .font(AppTypography.headline)
                Text("Hava uygulamalarında beklenen temel yüzeyler ve bizim karar motoruna en iyi bağlanacak sonraki adımlar.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(features, id: \.0) { feature in
                    InsightRow(
                        icon: "plus.circle.fill",
                        title: feature.0,
                        value: feature.1,
                        tint: AppTheme.teal
                    )
                }
            }
        }
    }
}

private struct ResetSection: View {
    let resetOnboarding: () -> Void

    var body: some View {
        Button(role: .destructive, action: resetOnboarding) {
            Label("Onboarding'i tekrar göster", systemImage: "arrow.counterclockwise")
                .font(AppTypography.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}
