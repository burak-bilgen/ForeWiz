import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var showResetConfirmation = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            SettingsBackground().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {

                    if let saveMessage = viewModel.saveMessage {
                        SettingsSaveBanner(message: saveMessage)
                    }

                    // MARK: Premium
                    SettingsSection(
                        title: L10n.text("settings_section_premium"),
                        icon: "crown.fill",
                        color: Color(red: 1.0, green: 0.78, blue: 0.25)
                    ) {
                        if viewModel.isPremium {
                            SettingsRow(
                                icon: "checkmark.seal.fill",
                                iconColor: Color(red: 0.35, green: 0.85, blue: 0.6),
                                title: L10n.text("settings_premium_active"),
                                subtitle: L10n.text("settings_premium_active_subtitle")
                            )
                        } else {
                            ForEach(PremiumFeature.allCases) { feature in
                                SettingsRow(
                                    icon: feature.systemImage,
                                    iconColor: Color(red: 0.4, green: 0.7, blue: 1.0),
                                    title: feature.localizedTitle,
                                    subtitle: feature.localizedDescription
                                )
                            }
                            Button {
                                HapticManager.medium()
                                viewModel.openPaywall()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 14))
                                    Text(L10n.text("settings_premium_upgrade"))
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundStyle(Color(red: 0.06, green: 0.1, blue: 0.22))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.82, blue: 0.3), Color(red: 1.0, green: 0.65, blue: 0.2)],
                                        startPoint: .leading, endPoint: .trailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                )
                            }
                            .padding(.top, 4)
                        }
                    }

                    // MARK: Appearance & language
                    SettingsSection(
                        title: L10n.text("settings_section_appearance"),
                        icon: "paintpalette.fill",
                        color: Color(red: 0.75, green: 0.5, blue: 1.0)
                    ) {
                        SettingsPickerRow(
                            icon: "circle.lefthalf.filled",
                            iconColor: Color(red: 0.75, green: 0.5, blue: 1.0),
                            title: L10n.text("settings_theme"),
                            selection: $viewModel.profile.appearance,
                            options: AppAppearance.allCases,
                            label: { $0.localizedTitle }
                        )
                        SettingsDivider()
                        SettingsPickerRow(
                            icon: "globe",
                            iconColor: Color(red: 0.4, green: 0.7, blue: 1.0),
                            title: L10n.text("settings_language"),
                            selection: languageSelection,
                            options: AppLanguage.allCases,
                            label: { $0.localizedTitle }
                        )
                    }

                    // MARK: Permissions
                    SettingsSection(
                        title: L10n.text("settings_section_permissions"),
                        icon: "lock.shield.fill",
                        color: Color(red: 0.4, green: 0.85, blue: 0.6)
                    ) {
                        SettingsRow(
                            icon: "location.fill",
                            iconColor: Color(red: 0.4, green: 0.7, blue: 1.0),
                            title: L10n.text("settings_permission_location"),
                            subtitle: L10n.text("settings_permission_location_desc")
                        )
                        SettingsDivider()
                        SettingsRow(
                            icon: "bell.badge.fill",
                            iconColor: Color(red: 1.0, green: 0.7, blue: 0.3),
                            title: L10n.text("settings_permission_notifications"),
                            subtitle: L10n.text("settings_permission_notifications_desc")
                        )
                        SettingsDivider()
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                SettingsIcon(systemName: "arrow.up.forward.app", color: Color(red: 0.4, green: 0.85, blue: 0.6))
                                Text(L10n.text("settings_open_ios_settings"))
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.3))
                            }
                        }
                    }

                    // MARK: Saved locations
                    SettingsSection(
                        title: L10n.text("settings_section_locations"),
                        icon: "mappin.and.ellipse",
                        color: Color(red: 1.0, green: 0.45, blue: 0.45)
                    ) {
                        SavedLocationsSection(profile: $viewModel.profile)
                    }

                    // MARK: Personal preferences
                    SettingsSection(
                        title: L10n.text("settings_units"),
                        icon: "ruler.fill",
                        color: Color(red: 0.4, green: 0.7, blue: 1.0)
                    ) {
                        HStack(spacing: 12) {
                            SettingsIcon(systemName: "thermometer.medium", color: Color(red: 0.4, green: 0.7, blue: 1.0))
                            Picker(L10n.text("settings_units"), selection: $viewModel.profile.unitSystem) {
                                ForEach(UnitSystem.allCases, id: \.self) { system in
                                    Text(system.localizedTitle).tag(system)
                                }
                            }
                            .pickerStyle(.segmented)
                            .colorMultiply(Color.white)
                        }
                    }

                    SettingsSection(
                        title: L10n.text("settings_temp_sensitivity"),
                        icon: "thermometer.sun.fill",
                        color: Color(red: 1.0, green: 0.55, blue: 0.3)
                    ) {
                        HStack(spacing: 12) {
                            SettingsIcon(systemName: "thermometer.sun.fill", color: Color(red: 1.0, green: 0.55, blue: 0.3))
                            Picker(L10n.text("settings_temp_sensitivity"), selection: $viewModel.profile.temperatureSensitivity) {
                                ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                                    Text(sensitivity.localizedTitle).tag(sensitivity)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    SettingsSection(
                        title: L10n.text("settings_activities"),
                        icon: "figure.run",
                        color: Color(red: 0.4, green: 0.85, blue: 0.6)
                    ) {
                        ForEach(Array(ActivityType.allCases.enumerated()), id: \.offset) { index, activity in
                            if index > 0 { SettingsDivider() }
                            SettingsActivityRow(
                                activity: activity,
                                isSelected: viewModel.profile.preferredActivities.contains(activity)
                            ) { toggle(activity) }
                        }
                    }

                    // MARK: Wardrobe
                    SettingsSection(
                        title: L10n.text("settings_wardrobe_title"),
                        icon: "tshirt.fill",
                        color: Color(red: 0.8, green: 0.65, blue: 1.0)
                    ) {
                        let items: [(icon: String, title: String, binding: Binding<Bool>)] = [
                            ("umbrella.fill", L10n.text("wardrobe_umbrella"), $viewModel.profile.wardrobe.hasUmbrella),
                            ("cloud.heavyrain.fill", L10n.text("wardrobe_raincoat"), $viewModel.profile.wardrobe.hasRaincoat),
                            ("snowflake", L10n.text("wardrobe_winter_coat"), $viewModel.profile.wardrobe.hasWinterCoat),
                            ("sunglasses", L10n.text("wardrobe_sunglasses"), $viewModel.profile.wardrobe.hasSunglasses),
                            ("hand.raised.fill", L10n.text("wardrobe_gloves"), $viewModel.profile.wardrobe.hasGloves),
                            ("flame.fill", L10n.text("wardrobe_thermals"), $viewModel.profile.wardrobe.hasThermals),
                        ]
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            if index > 0 { SettingsDivider() }
                            SettingsToggleRow(icon: item.icon, iconColor: Color(red: 0.8, green: 0.65, blue: 1.0), title: item.title, isOn: item.binding)
                        }
                    }

                    // MARK: Allergies
                    SettingsSection(
                        title: L10n.text("settings_allergy_title"),
                        icon: "allergens",
                        color: Color(red: 1.0, green: 0.7, blue: 0.3)
                    ) {
                        SettingsToggleRow(
                            icon: "leaf.fill",
                            iconColor: Color(red: 1.0, green: 0.7, blue: 0.3),
                            title: L10n.text("settings_allergy_enable"),
                            isOn: $viewModel.profile.allergyProfile.isEnabled
                        )
                        if viewModel.profile.allergyProfile.isEnabled {
                            SettingsDivider()
                            ForEach(Array(AllergyType.allCases.enumerated()), id: \.offset) { index, allergyType in
                                if index > 0 { SettingsDivider() }
                                SettingsAllergyRow(
                                    allergyType: allergyType,
                                    isSelected: viewModel.profile.allergyProfile.allergies.contains(allergyType)
                                ) {
                                    if viewModel.profile.allergyProfile.allergies.contains(allergyType) {
                                        viewModel.profile.allergyProfile.allergies.remove(allergyType)
                                    } else {
                                        viewModel.profile.allergyProfile.allergies.insert(allergyType)
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Notifications
                    SettingsSection(
                        title: L10n.text("settings_section_notifications"),
                        icon: "bell.badge.fill",
                        color: Color(red: 1.0, green: 0.45, blue: 0.45)
                    ) {
                        NotificationSettingsSection(profile: $viewModel.profile)
                    }

                    // MARK: About
                    SettingsSection(
                        title: L10n.text("settings_about_title"),
                        icon: "info.circle.fill",
                        color: Color(red: 0.4, green: 0.7, blue: 1.0)
                    ) {
                        SettingsAboutRow(label: L10n.text("settings_version"), value: appVersion)
                        SettingsDivider()
                        SettingsAboutRow(label: L10n.text("settings_data_source"), value: L10n.text("settings_data_apple_weather"))
                    }

                    // MARK: Reset
                    Button {
                        HapticManager.medium()
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14))
                            Text(L10n.text("settings_reset_title"))
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.2), lineWidth: 1))
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(L10n.text("settings_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: viewModel.profile) { viewModel.save() }
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

    // MARK: - Helpers

    private var languageSelection: Binding<AppLanguage> {
        Binding {
            viewModel.profile.language
        } set: { newLanguage in
            L10n.configure(language: newLanguage)
            viewModel.profile.language = newLanguage
        }
    }

    private func toggle(_ activity: ActivityType) {
        if viewModel.profile.preferredActivities.contains(activity) {
            viewModel.profile.preferredActivities.remove(activity)
        } else {
            viewModel.profile.preferredActivities.insert(activity)
        }
        if viewModel.profile.preferredActivities.isEmpty {
            viewModel.profile.preferredActivities.insert(.goingOutside)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Background

private struct SettingsBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.08, blue: 0.18), Color(red: 0.06, green: 0.12, blue: 0.26)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color(red: 0.75, green: 0.5, blue: 1.0).opacity(0.07))
                .frame(width: 300).blur(radius: 60)
                .offset(x: 120, y: -200)
            Circle()
                .fill(Color.blue.opacity(0.07))
                .frame(width: 240).blur(radius: 50)
                .offset(x: -100, y: 300)
        }
    }
}

// MARK: - Save banner

private struct SettingsSaveBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.6))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.35, green: 0.85, blue: 0.6).opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(red: 0.35, green: 0.85, blue: 0.6).opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Section container

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content

    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            VStack(spacing: 0) {
                content
            }
            .padding(16)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(color.opacity(0.12), lineWidth: 1))
        }
    }
}

// MARK: - Shared row components

private struct SettingsIcon: View {
    let systemName: String
    let color: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.18))
                .frame(width: 32, height: 32)
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1).padding(.leading, 44)
    }
}

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: icon, color: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct SettingsAboutRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .padding(.vertical, 4)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: icon, color: iconColor)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(iconColor)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

private struct SettingsPickerRow<T: Hashable>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: icon, color: iconColor)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(label(option)).tag(option)
                }
            }
            .tint(Color.white.opacity(0.6))
        }
        .padding(.vertical, 2)
    }
}

private struct SettingsActivityRow: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SettingsIcon(systemName: iconName, color: Color(red: 0.4, green: 0.85, blue: 0.6))
                Text(activity.localizedTitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color(red: 0.4, green: 0.85, blue: 0.6) : Color.white.opacity(0.25))
            }
            .padding(.vertical, 4)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var iconName: String {
        switch activity {
        case .running: "figure.run"
        case .walking: "figure.walk"
        case .cycling: "bicycle"
        case .goingOutside: "sun.max.fill"
        }
    }
}

private struct SettingsAllergyRow: View {
    let allergyType: AllergyType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                SettingsIcon(systemName: allergyType.icon, color: Color(red: 1.0, green: 0.7, blue: 0.3))
                Text(allergyType.localizedTitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color(red: 1.0, green: 0.7, blue: 0.3) : Color.white.opacity(0.25))
            }
            .padding(.vertical, 4)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
