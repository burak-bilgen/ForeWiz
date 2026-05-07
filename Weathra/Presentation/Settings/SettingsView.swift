import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    HeaderSection(saveMessage: viewModel.saveMessage)
                        .padding(.bottom, AppSpacing.xSmall)

                    SectionDivider(label: L10n.text("settings_section_appearance"))
                    AppearanceSection(profile: $viewModel.profile)
                    LanguageSection(profile: $viewModel.profile)

                    SectionDivider(label: L10n.text("settings_section_premium"))
                    PremiumSection(
                        isPremium: viewModel.isPremium,
                        onUpgrade: viewModel.openPaywall
                    )

                    SectionDivider(label: L10n.text("settings_section_permissions"))
                    PermissionManagementSection()

                    SectionDivider(label: L10n.text("settings_section_locations"))
                    SavedLocationsSection(profile: $viewModel.profile)

                    SectionDivider(label: L10n.text("settings_section_preferences"))
                    PersonalPreferencesSection(profile: $viewModel.profile)
                    WardrobeSettingsSection(profile: $viewModel.profile)
                    AllergySettingsSection(profile: $viewModel.profile)

                    SectionDivider(label: L10n.text("settings_section_notifications"))
                    NotificationSettingsSection(profile: $viewModel.profile)

                    SectionDivider(label: L10n.text("settings_section_app"))
                    AboutSection()
                    ResetSection(showConfirmation: $showResetConfirmation)
                }
                .padding(AppSpacing.medium)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(L10n.text("settings_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.profile) {
            viewModel.save()
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView(store: viewModel.subscriptionManager)
        }
        .confirmationDialog(
            L10n.text("settings_reset_title"),
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("settings_reset_confirm"), role: .destructive) {
                viewModel.resetOnboarding()
            }
            Button(L10n.text("settings_cancel"), role: .cancel) {}
        } message: {
            Text(L10n.text("settings_reset_message"))
        }
    }
}

private struct HeaderSection: View {
    let saveMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(L10n.text("settings_header_title"))
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(saveMessage ?? L10n.text("settings_header_subtitle"))
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
            title: L10n.text("settings_appearance_title"),
            subtitle: L10n.text("settings_appearance_subtitle")
        ) {
            Picker(L10n.text("settings_theme"), selection: $profile.appearance) {
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
            title: L10n.text("settings_language_title"),
            subtitle: L10n.text("settings_language_subtitle")
        ) {
            Picker(L10n.text("settings_language"), selection: languageSelection) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.localizedTitle).tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding {
            profile.language
        } set: { newLanguage in
            L10n.configure(language: newLanguage)
            profile.language = newLanguage
        }
    }
}

private struct PremiumSection: View {
    let isPremium: Bool
    let onUpgrade: () -> Void

    var body: some View {
        SettingsCard(
            icon: "crown.fill",
            title: L10n.text("settings_premium_title"),
            subtitle: isPremium
                ? L10n.text("settings_premium_active_subtitle")
                : L10n.text("settings_premium_upgrade_subtitle")
        ) {
            VStack(spacing: AppSpacing.medium) {
                if isPremium {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(AppTheme.success)
                        Text(L10n.text("settings_premium_active"))
                            .font(AppTypography.headline)
                            .foregroundStyle(AppTheme.success)
                    }
                } else {
                    ForEach(PremiumFeature.allCases) { feature in
                        HStack(spacing: AppSpacing.small) {
                            Image(systemName: feature.systemImage)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.localizedTitle)
                                    .font(AppTypography.caption.weight(.semibold))
                                Text(feature.localizedDescription)
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button(action: onUpgrade) {
                        Label(L10n.text("settings_premium_upgrade"), systemImage: "crown.fill")
                            .font(AppTypography.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.sunshine)
                }
            }
        }
    }
}

private struct PermissionManagementSection: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        SettingsCard(
            icon: "hand.raised.fill",
            title: L10n.text("settings_permissions_title"),
            subtitle: L10n.text("settings_permissions_subtitle")
        ) {
            VStack(spacing: AppSpacing.small) {
                SettingsInfoRow(
                    icon: "location.fill",
                    title: L10n.text("settings_permission_location"),
                    value: L10n.text("settings_permission_location_desc")
                )

                SettingsInfoRow(
                    icon: "bell.badge.fill",
                    title: L10n.text("settings_permission_notifications"),
                    value: L10n.text("settings_permission_notifications_desc")
                )

                Button(action: openSystemSettings) {
                    Label(L10n.text("settings_open_ios_settings"), systemImage: "arrow.up.forward.app.fill")
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
            title: L10n.text("settings_comfort_title"),
            subtitle: L10n.text("settings_comfort_subtitle")
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Picker(L10n.text("settings_units"), selection: $profile.unitSystem) {
                    ForEach(UnitSystem.allCases, id: \.self) { system in
                        Text(system.localizedTitle).tag(system)
                    }
                }
                .pickerStyle(.segmented)

                Picker(L10n.text("settings_temp_sensitivity"), selection: $profile.temperatureSensitivity) {
                    ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                        Text(sensitivity.localizedTitle).tag(sensitivity)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(L10n.text("settings_activities"))
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

private struct WardrobeSettingsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        SettingsCard(
            icon: "hanger",
            title: L10n.text("settings_wardrobe_title"),
            subtitle: L10n.text("settings_wardrobe_subtitle")
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Toggle(isOn: $profile.wardrobe.hasUmbrella) {
                    Label(L10n.text("wardrobe_umbrella"), systemImage: "umbrella.fill")
                }
                .tint(AppTheme.accent)

                Toggle(isOn: $profile.wardrobe.hasRaincoat) {
                    Label(L10n.text("wardrobe_raincoat"), systemImage: "cloud.heavyrain.fill")
                }
                .tint(AppTheme.accent)

                Toggle(isOn: $profile.wardrobe.hasWinterCoat) {
                    Label(L10n.text("wardrobe_winter_coat"), systemImage: "snowflake")
                }
                .tint(AppTheme.accent)

                Toggle(isOn: $profile.wardrobe.hasSunglasses) {
                    Label(L10n.text("wardrobe_sunglasses"), systemImage: "sunglasses")
                }
                .tint(AppTheme.accent)

                Toggle(isOn: $profile.wardrobe.hasGloves) {
                    Label(L10n.text("wardrobe_gloves"), systemImage: "hand.raised.fill")
                }
                .tint(AppTheme.accent)

                Toggle(isOn: $profile.wardrobe.hasThermals) {
                    Label(L10n.text("wardrobe_thermals"), systemImage: "flame.fill")
                }
                .tint(AppTheme.accent)
            }
        }
    }
}

private struct AllergySettingsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        SettingsCard(
            icon: "allergens",
            title: L10n.text("settings_allergy_title"),
            subtitle: L10n.text("settings_allergy_subtitle")
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Toggle(
                    L10n.text("settings_allergy_enable"),
                    isOn: $profile.allergyProfile.isEnabled
                )
                .font(AppTypography.body)

                if profile.allergyProfile.isEnabled {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        ForEach(AllergyType.allCases, id: \.self) { allergyType in
                            AllergyTypeToggle(
                                allergyType: allergyType,
                                isSelected: profile.allergyProfile.allergies.contains(allergyType)
                            ) {
                                if profile.allergyProfile.allergies.contains(allergyType) {
                                    profile.allergyProfile.allergies.remove(allergyType)
                                } else {
                                    profile.allergyProfile.allergies.insert(allergyType)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct AllergyTypeToggle: View {
    let allergyType: AllergyType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: allergyType.icon)
                    .font(.body)
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.secondaryText)
                    .frame(width: 24)

                Text(allergyType.localizedTitle)
                    .font(AppTypography.body)
                    .foregroundStyle(isSelected ? AppTheme.ink : AppTheme.secondaryText)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.secondaryText)
            }
            .padding(.vertical, AppSpacing.xSmall)
        }
    }
}
