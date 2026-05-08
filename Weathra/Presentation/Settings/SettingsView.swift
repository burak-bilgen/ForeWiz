import SwiftUI
import UIKit

/// Native `Form`-based settings screen. Sections, dividers, light/dark, dynamic type
/// and accessibility all handled by the system.
struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var showResetConfirmation = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            if let saveMessage = viewModel.saveMessage {
                Section {
                    Label(saveMessage, systemImage: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.green)
                        .listRowBackground(Color.clear)
                }
            }

            // MARK: Appearance & language
            Section(L10n.text("settings_section_appearance")) {
                Picker(L10n.text("settings_theme"), selection: $viewModel.profile.appearance) {
                    ForEach(AppAppearance.allCases, id: \.self) { appearance in
                        Text(appearance.localizedTitle).tag(appearance)
                    }
                }

                Picker(L10n.text("settings_language"), selection: languageSelection) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.localizedTitle).tag(language)
                    }
                }
            }

            // MARK: Premium
            Section {
                if viewModel.isPremium {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text(L10n.text("settings_premium_active"))
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                } else {
                    ForEach(PremiumFeature.allCases) { feature in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.localizedTitle)
                                    .font(.body)
                                Text(feature.localizedDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: feature.systemImage)
                                .foregroundStyle(.blue)
                        }
                    }
                    Button {
                        viewModel.openPaywall()
                    } label: {
                        Label(L10n.text("settings_premium_upgrade"), systemImage: "crown.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            } header: {
                Text(L10n.text("settings_section_premium"))
            } footer: {
                Text(viewModel.isPremium
                     ? L10n.text("settings_premium_active_subtitle")
                     : L10n.text("settings_premium_upgrade_subtitle"))
            }

            // MARK: Permissions
            Section {
                LabeledRow(
                    icon: "location.fill",
                    title: L10n.text("settings_permission_location"),
                    detail: L10n.text("settings_permission_location_desc")
                )
                LabeledRow(
                    icon: "bell.badge.fill",
                    title: L10n.text("settings_permission_notifications"),
                    detail: L10n.text("settings_permission_notifications_desc")
                )
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label(L10n.text("settings_open_ios_settings"), systemImage: "arrow.up.forward.app")
                }
            } header: {
                Text(L10n.text("settings_section_permissions"))
            } footer: {
                Text(L10n.text("settings_permissions_subtitle"))
            }

            // MARK: Saved locations
            Section {
                SavedLocationsSection(profile: $viewModel.profile)
            } header: {
                Text(L10n.text("settings_section_locations"))
            }

            // MARK: Personal preferences
            Section(L10n.text("settings_units")) {
                Picker(L10n.text("settings_units"), selection: $viewModel.profile.unitSystem) {
                    ForEach(UnitSystem.allCases, id: \.self) { system in
                        Text(system.localizedTitle).tag(system)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section(L10n.text("settings_temp_sensitivity")) {
                Picker(L10n.text("settings_temp_sensitivity"), selection: $viewModel.profile.temperatureSensitivity) {
                    ForEach(TemperatureSensitivity.allCases, id: \.self) { sensitivity in
                        Text(sensitivity.localizedTitle).tag(sensitivity)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section(L10n.text("settings_activities")) {
                ForEach(ActivityType.allCases, id: \.self) { activity in
                    ActivityRow(
                        activity: activity,
                        isSelected: viewModel.profile.preferredActivities.contains(activity)
                    ) {
                        toggle(activity)
                    }
                }
            }

            // MARK: Wardrobe
            Section {
                WardrobeToggle(
                    icon: "umbrella.fill",
                    title: L10n.text("wardrobe_umbrella"),
                    isOn: $viewModel.profile.wardrobe.hasUmbrella
                )
                WardrobeToggle(
                    icon: "cloud.heavyrain.fill",
                    title: L10n.text("wardrobe_raincoat"),
                    isOn: $viewModel.profile.wardrobe.hasRaincoat
                )
                WardrobeToggle(
                    icon: "snowflake",
                    title: L10n.text("wardrobe_winter_coat"),
                    isOn: $viewModel.profile.wardrobe.hasWinterCoat
                )
                WardrobeToggle(
                    icon: "sunglasses",
                    title: L10n.text("wardrobe_sunglasses"),
                    isOn: $viewModel.profile.wardrobe.hasSunglasses
                )
                WardrobeToggle(
                    icon: "hand.raised.fill",
                    title: L10n.text("wardrobe_gloves"),
                    isOn: $viewModel.profile.wardrobe.hasGloves
                )
                WardrobeToggle(
                    icon: "flame.fill",
                    title: L10n.text("wardrobe_thermals"),
                    isOn: $viewModel.profile.wardrobe.hasThermals
                )
            } header: {
                Text(L10n.text("settings_wardrobe_title"))
            } footer: {
                Text(L10n.text("settings_wardrobe_subtitle"))
            }

            // MARK: Allergies
            Section {
                Toggle(L10n.text("settings_allergy_enable"), isOn: $viewModel.profile.allergyProfile.isEnabled)
                if viewModel.profile.allergyProfile.isEnabled {
                    ForEach(AllergyType.allCases, id: \.self) { allergyType in
                        AllergyRow(
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
            } header: {
                Text(L10n.text("settings_allergy_title"))
            } footer: {
                Text(L10n.text("settings_allergy_subtitle"))
            }

            // MARK: Notifications
            Section {
                NotificationSettingsSection(profile: $viewModel.profile)
            } header: {
                Text(L10n.text("settings_section_notifications"))
            }

            // MARK: About
            Section(L10n.text("settings_about_title")) {
                LabeledContent(L10n.text("settings_version"), value: appVersion)
                LabeledContent(
                    L10n.text("settings_data_source"),
                    value: L10n.text("settings_data_apple_weather")
                )
            }

            // MARK: Reset
            Section {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label(L10n.text("settings_reset_confirm"), systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text(L10n.text("settings_reset_title"))
            } footer: {
                Text(L10n.text("settings_privacy_note"))
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background { Color(UIColor.systemGroupedBackground) }
        .navigationTitle(L10n.text("settings_title"))
        .navigationBarTitleDisplayMode(.large)
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

// MARK: - Form rows

private struct LabeledRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.blue)
        }
    }
}

private struct ActivityRow: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 24)
                Text(activity.localizedTitle)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray.opacity(0.5))
            }
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

private struct WardrobeToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: icon)
        }
        .tint(.blue)
    }
}

private struct AllergyRow: View {
    let allergyType: AllergyType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: allergyType.icon)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 24)
                Text(allergyType.localizedTitle)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray.opacity(0.5))
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
