import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var showResetConfirmation = false
    @State private var languageKey: String = L10n.currentLanguageCode
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SettingsBackground().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.text("settings_profile_title"))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text(L10n.text("settings_profile_subtitle"))
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)

                    SettingsSaveBanner(message: viewModel.saveMessage ?? "")
                        .opacity(viewModel.saveMessage != nil ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.saveMessage != nil)

                SettingsSection(
                    title: L10n.text("settings_units"),
                    icon: "thermometer.medium",
                    color: Color(red: 0.4, green: 0.7, blue: 1.0)
                ) {
                    HStack(spacing: 14) {
                        SettingsIcon(
                            systemName: "thermometer.medium",
                            color: Color(red: 0.4, green: 0.7, blue: 1.0)
                        )
                        FlowLayout(spacing: 8) {
                            ForEach(UnitSystem.allCases, id: \.self) { option in
                                UnitOptionButton(
                                    option: option,
                                    isSelected: option == viewModel.profile.unitSystem
                                ) {
                                    HapticManager.selection()
                                    viewModel.profile.unitSystem = option
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }

                SettingsSection(
                    title: L10n.text("settings_temp_sensitivity"),
                    icon: "thermometer.sun.fill",
                    color: Color(red: 1.0, green: 0.55, blue: 0.3)
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("settings_temp_sensitivity_desc"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .fixedSize(horizontal: false, vertical: true)
                        SettingsSensitivitySelector(selection: $viewModel.profile.temperatureSensitivity)
                    }
                }

                SettingsSection(
                    title: L10n.text("settings_activities"),
                    icon: "figure.run",
                    color: Color(red: 0.4, green: 0.85, blue: 0.6)
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.text("settings_activities_desc"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(Array(ActivityType.allCases.enumerated()), id: \.offset) { index, activity in
                            if index > 0 { SettingsDivider() }
                            SettingsActivityRow(
                                activity: activity,
                                isSelected: viewModel.profile.preferredActivities.contains(activity)
                            ) { toggle(activity) }
                        }
                    }
                }

                SettingsSection(
                    title: L10n.text("settings_daily_rhythm"),
                    icon: "sunrise.fill",
                    color: Color(red: 1.0, green: 0.7, blue: 0.35)
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 14) {
                            SettingsIcon(systemName: "sunrise.fill", color: Color(red: 1.0, green: 0.7, blue: 0.35))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(L10n.text("settings_wake_time"))
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                                Text(L10n.text("settings_wake_desc"))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.white.opacity(0.38))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .layoutPriority(1)
                            Spacer(minLength: 8)
                            Picker("", selection: Binding(
                                get: { viewModel.profile.wakeUpTime?.hour ?? 7 },
                                set: { viewModel.profile.wakeUpTime = DateComponents(hour: $0, minute: 0) }
                            )) {
                                ForEach(5...11, id: \.self) { hour in
                                    Text(String(format: "%02d:00", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.white.opacity(0.6))
                        }
                        .padding(.vertical, 4)

                        SettingsDivider()

                        HStack(spacing: 14) {
                            SettingsIcon(systemName: "figure.run", color: Color(red: 1.0, green: 0.7, blue: 0.35))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(L10n.text("settings_workout_time"))
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                                Text(L10n.text("settings_workout_desc"))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.white.opacity(0.38))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .layoutPriority(1)
                            Spacer(minLength: 8)
                            Picker("", selection: Binding(
                                get: { viewModel.profile.usualWorkoutTime?.hour ?? 8 },
                                set: { viewModel.profile.usualWorkoutTime = DateComponents(hour: $0, minute: 0) }
                            )) {
                                ForEach(6...22, id: \.self) { hour in
                                    Text(String(format: "%02d:00", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.white.opacity(0.6))
                        }
                        .padding(.vertical, 4)
                    }
                }

                SettingsSection(
                    title: L10n.text("settings_section_notifications"),
                    icon: "bell.badge.fill",
                    color: Color(red: 1.0, green: 0.45, blue: 0.45)
                ) {
                    NotificationSettingsSection(profile: $viewModel.profile)
                }

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
                        .padding(.vertical, 4)
                    }
                }

                SettingsSection(
                    title: L10n.text("settings_language"),
                    icon: "globe",
                    color: Color(red: 0.4, green: 0.7, blue: 1.0)
                ) {
                    SettingsPickerRow(
                        icon: "globe",
                        iconColor: Color(red: 0.4, green: 0.7, blue: 1.0),
                        title: L10n.text("settings_language"),
                        selection: languageSelection,
                        options: AppLanguage.allCases,
                        label: { $0.localizedTitle }
                    )
                }

                SettingsSection(
                    title: L10n.text("settings_about_title"),
                    icon: "info.circle.fill",
                    color: Color(red: 0.4, green: 0.7, blue: 1.0)
                ) {
                    SettingsAboutRow(label: L10n.text("settings_version"), value: appVersion)
                    SettingsDivider()
                    SettingsAboutRow(label: L10n.text("settings_data_source"), value: L10n.text("settings_data_apple_weather"))
                }

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
                    .background(Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.2), lineWidth: 1))
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.bottom, 12)
        }
        .navigationTitle(L10n.text("settings_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.light()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
        }
        .dynamicTypeSize(.large ... .xxxLarge)
        .onChange(of: viewModel.profile) { viewModel.save() }
        .onChange(of: viewModel.profile.language) { _, newLang in
            languageKey = newLang.localeIdentifier ?? "system"
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
        HapticManager.selection()
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
        AnimatedOrbBackground(
            primary:   Color(red: 0.55, green: 0.35, blue: 1.00),
            secondary: Color(red: 0.25, green: 0.50, blue: 1.00),
            tertiary:  Color(red: 0.20, green: 0.75, blue: 0.65)
        )
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
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .padding(.leading, 4)
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(color.opacity(0.10), lineWidth: 1))
        }
    }
}

// MARK: - Shared row components

private struct SettingsIcon: View {
    let systemName: String
    let color: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(color.opacity(0.16))
                .frame(width: 34, height: 34)
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 50)
    }
}

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(systemName: icon, color: iconColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.38))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
        }
        .padding(.vertical, 10)
    }
}

private struct SettingsInfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SettingsIcon(systemName: icon, color: color)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.42))
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .padding(.vertical, 8)
    }
}

private struct SettingsAboutRow: View {
    let label: String
    let value: String
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                aboutLabel
                Spacer(minLength: 12)
                aboutValue
            }

            VStack(alignment: .leading, spacing: 4) {
                aboutLabel
                aboutValue
            }
        }
        .padding(.vertical, 10)
    }

    private var aboutLabel: some View {
        Text(label)
            .font(.system(size: 15))
            .foregroundStyle(.white)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var aboutValue: some View {
        Text(value)
            .font(.system(size: 14))
            .foregroundStyle(Color.white.opacity(0.45))
            .lineLimit(2)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(systemName: icon, color: iconColor)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .tint(iconColor)
                .labelsHidden()
        }
        .padding(.vertical, 8)
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
        HStack(spacing: 14) {
            SettingsIcon(systemName: icon, color: iconColor)
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Spacer(minLength: 8)
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(label(option)).tag(option)
                }
            }
            .tint(Color.white.opacity(0.55))
        }
        .padding(.vertical, 6)
    }
}

private struct SettingsSensitivitySelector: View {
    @Binding var selection: TemperatureSensitivity

    private let options: [(TemperatureSensitivity, String, String)] = [
        (.getsColdEasily, "snowflake",          "sensitivity_cold"),
        (.normal,         "thermometer.medium", "sensitivity_normal"),
        (.getsHotEasily,  "sun.max.fill",       "sensitivity_hot"),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
            ForEach(options, id: \.0) { sensitivity, icon, key in
                let selected = selection == sensitivity
                Button {
                    HapticManager.selection()
                    selection = sensitivity
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(selected ? Color(red: 1.0, green: 0.55, blue: 0.3) : Color.white.opacity(0.4))
                        Text(L10n.text(key))
                            .font(.system(size: 12, weight: selected ? .semibold : .regular))
                            .foregroundStyle(selected ? Color(red: 1.0, green: 0.55, blue: 0.3) : Color.white.opacity(0.4))
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selected
                            ? Color(red: 1.0, green: 0.55, blue: 0.3).opacity(0.14)
                            : Color.white.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(
                            selected ? Color(red: 1.0, green: 0.55, blue: 0.3).opacity(0.35) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: selected)
            }
        }
    }
}

private struct SettingsActivityRow: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                SettingsIcon(systemName: iconName, color: Color(red: 0.4, green: 0.85, blue: 0.6))
                Text(activity.localizedTitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color(red: 0.4, green: 0.85, blue: 0.6) : Color.white.opacity(0.2))
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            }
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
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

private struct UnitOptionButton: View {
    let option: UnitSystem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(option.localizedTitle)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color(red: 0.4, green: 0.7, blue: 1.0) : Color.white.opacity(0.5))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.15)
                        : Color.white.opacity(0.07),
                    in: Capsule()
                )
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.4) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
    }
}
