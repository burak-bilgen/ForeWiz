import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var showDeleteAllDataConfirmation = false
    @State private var showShareSheet = false
    @State private var exportJSON = ""
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

                SettingsSection(
                    title: L10n.text("settings_temp_sensitivity"),
                    icon: "thermometer.sun.fill",
                    color: Color(red: 1.0, green: 0.55, blue: 0.3)
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("settings_temp_sensitivity_desc"))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                        SettingsSensitivitySelector(selection: $viewModel.profile.temperatureSensitivity)
                            .padding(.bottom, 6)
                    }
                }

                SettingsSection(
                    title: L10n.text("settings_activities"),
                    icon: "figure.run",
                    color: Color(red: 0.4, green: 0.85, blue: 0.6)
                ) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L10n.text("settings_activities_desc"))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 6)
                        ForEach(Array(ActivityType.allCases.enumerated()), id: \.offset) { index, activity in
                            if index > 0 { SettingsDivider() }
                            SettingsActivityRow(
                                activity: activity,
                                isSelected: viewModel.profile.preferredActivities.contains(activity)
                            ) { toggle(activity) }
                        }
                        .padding(.bottom, 6)
                    }
                }

                SettingsSection(
                    title: L10n.text("settings_daily_rhythm"),
                    icon: "sunrise.fill",
                    color: Color(red: 1.0, green: 0.7, blue: 0.35)
                ) {
                    wakeTimePicker
                }

                SettingsSection(
                    title: L10n.text("settings_section_notifications"),
                    icon: "bell.badge.fill",
                    color: Color(red: 1.0, green: 0.45, blue: 0.45)
                ) {
                    NotificationSettingsSection(profile: $viewModel.profile)
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
                    Task { await HapticEngine.shared.medium() }
                    showDeleteAllDataConfirmation = true
                } label: {
                    deleteButtonLabelWithStroke()
                }

                .padding(.bottom, 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .refreshable { }
            .safeAreaPadding(.bottom, 12)
        }
        .navigationTitle(L10n.text("settings_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await HapticEngine.shared.light() }
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
        }
        .onChange(of: viewModel.profile) { viewModel.save() }
        .onChange(of: viewModel.profile.language) { _, newLang in
            languageKey = newLang.localeIdentifier ?? "system"
        }
        .confirmationDialog(
            L10n.text("settings_delete_all_data_title"),
            isPresented: $showDeleteAllDataConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.text("settings_delete_all_data_confirm"), role: .destructive) {
                viewModel.deleteAllData()
            }
            Button(L10n.text("settings_cancel"), role: .cancel) {}
        } message: {
            Text(L10n.text("settings_delete_all_data_message"))
        }

        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [exportJSON])
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
        Task { await HapticEngine.shared.selectionChanged() }
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
    
    private var wakeTimePicker: some View {
        HStack(spacing: 14) {
            let accentColor = Color(red: 1.0, green: 0.7, blue: 0.35)
            SettingsIcon(systemName: "sunrise.fill", color: accentColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text("settings_wake_time"))
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Text(L10n.text("settings_wake_desc"))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.38))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
            wakeTimeSelector
        }
        .padding(.top, 14)
        .padding(.bottom, 20)
    }
    
    private var wakeTimeSelector: some View {
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
    
    private func deleteButtonLabel() -> some View {
        HStack(spacing: 10) {
            Image(systemName: "trash")
                .font(.system(size: 14))
            Text(L10n.text("settings_delete_all_data_title"))
                .font(.system(size: 15, weight: .medium))
        }
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func deleteButtonLabelWithStroke() -> some View {
        deleteButtonLabel()
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
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
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                        .font(.system(size: 13))
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
                .font(.system(size: 13))
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
                    Task { await HapticEngine.shared.selectionChanged() }
                    selection = sensitivity
                } label: {
                    sensitivityButtonLabel(icon: icon, key: key, selected: selected)
                }
                .buttonStyle(.fullTapArea)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: selected)
            }
        }
    }
    
    private func sensitivityButtonLabel(icon: String, key: String, selected: Bool) -> some View {
        let selectedColor = Color(red: 1.0, green: 0.55, blue: 0.3)
        let unselectedColor = Color.white.opacity(0.4)
        
        return VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(selected ? selectedColor : unselectedColor)
            Text(L10n.text(key))
                .font(.system(size: 12, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? selectedColor : unselectedColor)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.vertical, 10)
        .background(
            selected
                ? selectedColor.opacity(0.14)
                : Color.white.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(
                selected ? selectedColor.opacity(0.35) : Color.white.opacity(0.08),
                lineWidth: 1
            )
        )
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
            .padding(.vertical, 5)
        }
        .buttonStyle(.fullTapArea)
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
