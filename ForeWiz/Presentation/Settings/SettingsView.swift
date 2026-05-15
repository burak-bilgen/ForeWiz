import SwiftUI
import SwiftData
import UIKit

// MARK: - Liquid Glass Settings View
struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var showDeleteAllDataConfirmation = false
    @State private var showShareSheet = false
    @State private var exportJSON = ""
    @State private var appeared = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LiquidOrbBackground(palette: .default)
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.text("settings_profile_title"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(L10n.text("settings_profile_subtitle"))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .settingsCardEntrance(appeared: appeared, index: 0)

                    // Temperature Sensitivity
                    SettingsCard(
                        title: L10n.text("settings_temp_sensitivity"),
                        icon: "thermometer.sun.fill",
                        color: AppTheme.ember
                    ) {
                        Text(L10n.text("settings_temp_sensitivity_desc"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                        SettingsSensitivitySelector(selection: $viewModel.profile.temperatureSensitivity)
                            .padding(.bottom, 6)
                    }
                    .settingsCardEntrance(appeared: appeared, index: 1)

                    // Activities
                    SettingsCard(
                        title: L10n.text("settings_activities"),
                        icon: "figure.run",
                        color: AppTheme.success
                    ) {
                        Text(L10n.text("settings_activities_desc"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 6)
                        ForEach(Array(ActivityType.allCases.enumerated()), id: \.offset) { index, activity in
                            if index > 0 { Divider().background(.white.opacity(0.04)) }
                            SettingsActivityRow(
                                activity: activity,
                                isSelected: viewModel.profile.preferredActivities.contains(activity)
                            ) { toggle(activity) }
                        }
                        .padding(.bottom, 6)
                    }
                    .settingsCardEntrance(appeared: appeared, index: 2)

                    // Daily Rhythm
                    SettingsCard(
                        title: L10n.text("settings_daily_rhythm"),
                        icon: "sunrise.fill",
                        color: AppTheme.sunshine
                    ) {
                        WakeTimePicker(wakeTime: $viewModel.profile.wakeUpTime)
                    }
                    .settingsCardEntrance(appeared: appeared, index: 3)

                    // Notifications
                    SettingsCard(
                        title: L10n.text("settings_section_notifications"),
                        icon: "bell.badge.fill",
                        color: AppTheme.coral
                    ) {
                        NotificationSettingsSection(profile: $viewModel.profile)
                    }
                    .settingsCardEntrance(appeared: appeared, index: 4)

                    // Language
                    SettingsCard(
                        title: L10n.text("settings_language"),
                        icon: "globe",
                        color: AppTheme.liquidAccent
                    ) {
                        SettingsPickerRow(
                            icon: "globe",
                            iconColor: AppTheme.liquidAccent,
                            title: L10n.text("settings_language"),
                            selection: languageSelection,
                            options: AppLanguage.allCases,
                            label: { $0.localizedTitle }
                        )
                    }
                    .settingsCardEntrance(appeared: appeared, index: 5)

                    // About
                    SettingsCard(
                        title: L10n.text("settings_about_title"),
                        icon: "info.circle.fill",
                        color: AppTheme.liquidAccent
                    ) {
                        SettingsInfoRow(icon: "doc.text", color: .white.opacity(0.4), text: L10n.text("settings_version") + " " + appVersion)
                        SettingsInfoRow(icon: "map.fill", color: AppTheme.sky, text: L10n.text("settings_data_apple_weather"))
                    }
                    .settingsCardEntrance(appeared: appeared, index: 6)

                    // Delete Data
                    LiquidGlassButton(L10n.text("settings_delete_all_data_title"), icon: "trash", style: .danger, haptic: .heavy) {
                        showDeleteAllDataConfirmation = true
                    }
                    .frame(maxWidth: .infinity)
                    .settingsCardEntrance(appeared: appeared, index: 7)

                    // Save banner
                    if let message = viewModel.saveMessage {
                        SettingsSaveBanner(message: message)
                            .settingsCardEntrance(appeared: true, index: 0)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .safeAreaPadding(.bottom, 12)
        }
        .navigationTitle(L10n.text("settings_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticEngine.shared.light()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear { animateAppearance() }
        .onChange(of: viewModel.profile) { viewModel.save() }
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

    private func animateAppearance() {
        withAnimation(.easeOut(duration: 0.6)) {
            appeared = true
        }
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding {
            viewModel.profile.language
        } set: { newLanguage in
            L10n.configure(language: newLanguage)
            viewModel.profile.language = newLanguage
        }
    }

    private func toggle(_ activity: ActivityType) {
        HapticEngine.shared.selectionChanged()
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

// MARK: - Settings Card

private struct SettingsCard<Content: View>: View {
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(color.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            .padding(.leading, 4)

            LiquidGlassCard(accentColor: color, innerPadding: 8) {
                content
            }
        }
    }
}

// MARK: - Supporting Views

private struct SettingsIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(color.opacity(0.14))
                .frame(width: 34, height: 34)
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

private struct SettingsInfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
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
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(label(option)).tag(option)
                }
            }
            .tint(.white.opacity(0.55))
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Sensitivity Selector

private struct SettingsSensitivitySelector: View {
    @Binding var selection: TemperatureSensitivity

    private let options: [(TemperatureSensitivity, String, String)] = [
        (.getsColdEasily, "snowflake", "sensitivity_cold"),
        (.normal, "thermometer.medium", "sensitivity_normal"),
        (.getsHotEasily, "sun.max.fill", "sensitivity_hot"),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
            ForEach(options, id: \.0) { sensitivity, icon, key in
                let selected = selection == sensitivity
                Button {
                    HapticEngine.shared.selectionChanged()
                    selection = sensitivity
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(selected ? AppTheme.ember : .white.opacity(0.35))
                        Text(L10n.text(key))
                            .font(.system(size: 12, weight: selected ? .bold : .medium, design: .rounded))
                            .foregroundStyle(selected ? AppTheme.ember : .white.opacity(0.35))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .padding(.vertical, 10)
                    .background(
                        selected
                            ? AppTheme.ember.opacity(0.14)
                            : .white.opacity(0.04),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selected ? AppTheme.ember.opacity(0.35) : .white.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: selected)
            }
        }
    }
}

// MARK: - Activity Row

private struct SettingsActivityRow: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                SettingsIcon(systemName: iconName, color: AppTheme.success)
                Text(activity.localizedTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? AppTheme.success : .white.opacity(0.2))
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
            }
            .padding(.vertical, 5)
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

// MARK: - Wake Time Picker

private struct WakeTimePicker: View {
    @Binding var wakeTime: DateComponents?

    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(systemName: "sunrise.fill", color: AppTheme.sunshine)
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text("settings_wake_time"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(L10n.text("settings_wake_desc"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Picker("", selection: Binding(
                get: { wakeTime?.hour ?? 7 },
                set: { wakeTime = DateComponents(hour: $0, minute: 0) }
            )) {
                ForEach(5...11, id: \.self) { hour in
                    Text(L10n.formatted("time_format_full", hour)).tag(hour)
                }
            }
            .pickerStyle(.menu)
            .tint(.white.opacity(0.6))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Save Banner

private struct SettingsSaveBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.success)
            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.success.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.success.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Card Entrance

private struct SettingsCardEntranceModifier: ViewModifier {
    let appeared: Bool
    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.82)
                    .delay(Double(index) * 0.06),
                value: appeared
            )
    }
}

private extension View {
    func settingsCardEntrance(appeared: Bool, index: Int) -> some View {
        modifier(SettingsCardEntranceModifier(appeared: appeared, index: index))
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: UserPreferencesModel.self, WeatherSnapshotModel.self)
    let preferencesRepo = SwiftDataPreferencesRepository(modelContext: container.mainContext)
    NavigationStack {
        SettingsView(
            viewModel: SettingsViewModel(
                profile: .default,
                updateUserPreferencesUseCase: DefaultUpdateUserPreferencesUseCase(
                    preferencesRepository: preferencesRepo
                ),
                onProfileSaved: { _ in }
            )
        )
    }
}
