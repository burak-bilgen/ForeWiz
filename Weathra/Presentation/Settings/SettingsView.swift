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

                    SectionDivider(label: String(localized: "settings_section_appearance"))
                    AppearanceSection(profile: $viewModel.profile)
                    LanguageSection(profile: $viewModel.profile)

                    SectionDivider(label: String(localized: "settings_section_premium"))
                    PremiumSection(
                        isPremium: viewModel.isPremium,
                        onUpgrade: viewModel.openPaywall
                    )

                    SectionDivider(label: String(localized: "settings_section_permissions"))
                    PermissionManagementSection()

                    SectionDivider(label: String(localized: "settings_section_locations"))
                    SavedLocationsSection(profile: $viewModel.profile)

                    SectionDivider(label: String(localized: "settings_section_preferences"))
                    PersonalPreferencesSection(profile: $viewModel.profile)
                    WardrobeSettingsSection(profile: $viewModel.profile)

                    SectionDivider(label: String(localized: "settings_section_notifications"))
                    NotificationSettingsSection(profile: $viewModel.profile)

                    SectionDivider(label: String(localized: "settings_section_app"))
                    AboutSection()
                    ResetSection(showConfirmation: $showResetConfirmation)
                }
                .padding(AppSpacing.medium)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(String(localized: "settings_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.profile) {
            viewModel.save()
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView(store: viewModel.subscriptionManager)
        }
        .confirmationDialog(
            String(localized: "settings_reset_title"),
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings_reset_confirm"), role: .destructive) {
                viewModel.resetOnboarding()
            }
            Button(String(localized: "settings_cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings_reset_message"))
        }
    }
}

private struct HeaderSection: View {
    let saveMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(String(localized: "settings_header_title"))
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(saveMessage ?? String(localized: "settings_header_subtitle"))
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
            title: String(localized: "settings_appearance_title"),
            subtitle: String(localized: "settings_appearance_subtitle")
        ) {
            Picker(String(localized: "settings_theme"), selection: $profile.appearance) {
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
            title: String(localized: "settings_language_title"),
            subtitle: String(localized: "settings_language_subtitle")
        ) {
            Picker(String(localized: "settings_language"), selection: $profile.language) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.localizedTitle).tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct PremiumSection: View {
    let isPremium: Bool
    let onUpgrade: () -> Void

    var body: some View {
        SettingsCard(
            icon: "crown.fill",
            title: String(localized: "settings_premium_title"),
            subtitle: isPremium
                ? String(localized: "settings_premium_active_subtitle")
                : String(localized: "settings_premium_upgrade_subtitle")
        ) {
            VStack(spacing: AppSpacing.medium) {
                if isPremium {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(AppTheme.success)
                        Text(String(localized: "settings_premium_active"))
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
                        Label(String(localized: "settings_premium_upgrade"), systemImage: "crown.fill")
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
            title: String(localized: "settings_permissions_title"),
            subtitle: String(localized: "settings_permissions_subtitle")
        ) {
            VStack(spacing: AppSpacing.small) {
                SettingsInfoRow(
                    icon: "location.fill",
                    title: String(localized: "settings_permission_location"),
                    value: String(localized: "settings_permission_location_desc")
                )

                SettingsInfoRow(
                    icon: "bell.badge.fill",
                    title: String(localized: "settings_permission_notifications"),
                    value: String(localized: "settings_permission_notifications_desc")
                )

                Button(action: openSystemSettings) {
                    Label(String(localized: "settings_open_ios_settings"), systemImage: "arrow.up.forward.app.fill")
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
            title: String(localized: "settings_comfort_title"),
            subtitle: String(localized: "settings_comfort_subtitle")
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Picker(String(localized: "settings_units"), selection: $profile.unitSystem) {
                    ForEach(UnitSystem.allCases, id: \.self) { system in
                        Text(system.localizedTitle).tag(system)
                    }
                }
                .pickerStyle(.segmented)

                Picker(String(localized: "settings_temp_sensitivity"), selection: $profile.temperatureSensitivity) {
                    ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                        Text(sensitivity.localizedTitle).tag(sensitivity)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(String(localized: "settings_activities"))
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
            title: String(localized: "settings_wardrobe_title"),
            subtitle: String(localized: "settings_wardrobe_subtitle")
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Toggle(isOn: $profile.wardrobe.hasUmbrella) {
                    Label(String(localized: "wardrobe_umbrella"), systemImage: "umbrella.fill")
                }
                .tint(AppTheme.accent)

                Toggle(isOn: $profile.wardrobe.hasRaincoat) {
                    Label(String(localized: "wardrobe_raincoat"), systemImage: "cloud.heavyrain.fill")
                }
                .tint(AppTheme.accent)

                Toggle(isOn: $profile.wardrobe.hasWinterCoat) {
                    Label(String(localized: "wardrobe_winter_coat"), systemImage: "snowflake")
                }
                .tint(AppTheme.accent)

                Toggle(isOn: $profile.wardrobe.hasSunglasses) {
                    Label(String(localized: "wardrobe_sunglasses"), systemImage: "sunglasses")
                }
                .tint(AppTheme.accent)

                Toggle(isOn: $profile.wardrobe.hasGloves) {
                    Label(String(localized: "wardrobe_gloves"), systemImage: "hand.raised.fill")
                }
                .tint(AppTheme.accent)

                Toggle(isOn: $profile.wardrobe.hasThermals) {
                    Label(String(localized: "wardrobe_thermals"), systemImage: "flame.fill")
                }
                .tint(AppTheme.accent)
            }
        }
    }
}

private struct NotificationSettingsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        SettingsCard(
            icon: "bell.badge.fill",
            title: String(localized: "settings_notifications_title"),
            subtitle: String(localized: "settings_notifications_subtitle")
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Stepper(
                    String(localized: "settings_daily_limit") + " \(profile.maximumDailyNotifications)",
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

private struct AboutSection: View {
    var body: some View {
        SettingsCard(
            icon: "info.circle.fill",
            title: String(localized: "settings_about_title"),
            subtitle: String(localized: "settings_about_subtitle")
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Text(String(localized: "settings_version"))
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text(appVersion)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                HStack {
                    Text(String(localized: "settings_data_source"))
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text(String(localized: "settings_data_apple_weather"))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Text(String(localized: "settings_privacy_note"))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct SectionDivider: View {
    let label: String

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Rectangle()
                .fill(AppTheme.secondaryText.opacity(0.18))
                .frame(height: 1)

            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)

            Rectangle()
                .fill(AppTheme.secondaryText.opacity(0.18))
                .frame(height: 1)
        }
        .padding(.horizontal, AppSpacing.xSmall)
    }
}

private struct SavedLocationsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        SettingsCard(
            icon: "mappin.and.ellipse",
            title: String(localized: "settings_saved_locations_title"),
            subtitle: String(localized: "settings_saved_locations_subtitle")
        ) {
            VStack(spacing: AppSpacing.small) {
                ForEach(profile.savedLocations) { location in
                    NavigationLink {
                        SavedLocationDetailView(location: location, onSave: { updated in
                            updateLocation(updated)
                        }, onDelete: {
                            deleteLocation(location)
                        })
                    } label: {
                        SavedLocationRow(location: location, isSelected: location.id == profile.selectedLocationID)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                Button(action: addLocation) {
                    Label(String(localized: "settings_add_location"), systemImage: "plus.circle.fill")
                        .font(AppTypography.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
            }
        }
    }

    private func updateLocation(_ updated: SavedLocation) {
        guard let index = profile.savedLocations.firstIndex(where: { $0.id == updated.id }) else {
            return
        }

        profile.savedLocations[index] = updated
    }

    private func deleteLocation(_ location: SavedLocation) {
        guard location.id != "current-location" else {
            return
        }

        profile.savedLocations.removeAll { $0.id == location.id }

        if profile.selectedLocationID == location.id {
            profile.selectedLocationID = "current-location"
        }
    }

    private func addLocation() {
        let newLocation = SavedLocation(
            name: String(localized: "settings_new_location"),
            latitude: 0,
            longitude: 0,
            address: String(localized: "settings_search_location")
        )

        profile.savedLocations.append(newLocation)
    }
}

private struct SavedLocationRow: View {
    let location: SavedLocation
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: location.id == "current-location" ? "location.fill" : "mappin.and.ellipse")
                .font(.subheadline.weight(.semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(location.name)
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Text(location.address)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: AppSpacing.small)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xSmall)
        .background(AppTheme.elevatedSurface.opacity(0.86), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
    }
}

private struct SavedLocationDetailView: View {
    @State private var name: String
    @State private var address: String

    let location: SavedLocation
    let onSave: (SavedLocation) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    init(location: SavedLocation, onSave: @escaping (SavedLocation) -> Void, onDelete: @escaping () -> Void) {
        self.location = location
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: location.name)
        _address = State(initialValue: location.address)
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                GlassCard {
                    VStack(spacing: AppSpacing.medium) {
                        LabeledContent(String(localized: "settings_location_name")) {
                            TextField(String(localized: "settings_location_name"), text: $name)
                                .multilineTextAlignment(.trailing)
                        }

                        LabeledContent(String(localized: "settings_address")) {
                            TextField(String(localized: "settings_address"), text: $address)
                                .multilineTextAlignment(.trailing)
                        }

                        LabeledContent(String(localized: "settings_coordinates")) {
                            Text("\(location.latitude.formatted(.number.precision(.fractionLength(4)))), \(location.longitude.formatted(.number.precision(.fractionLength(4))))")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }

                if location.id != "current-location" {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label(String(localized: "settings_delete_location"), systemImage: "trash")
                            .font(AppTypography.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(String(localized: "settings_edit_location"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "settings_save")) {
                    var updated = location
                    updated.name = name
                    updated.address = address
                    onSave(updated)
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

private struct ResetSection: View {
    @Binding var showConfirmation: Bool

    var body: some View {
        SettingsCard(
            icon: "arrow.counterclockwise.circle.fill",
            title: String(localized: "settings_reset_title"),
            subtitle: String(localized: "settings_reset_subtitle")
        ) {
            Button(action: { showConfirmation = true }) {
                Label(String(localized: "settings_reset_confirm"), systemImage: "arrow.counterclockwise")
                    .font(AppTypography.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.danger)
        }
    }
}

