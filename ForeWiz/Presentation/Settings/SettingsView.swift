import SwiftUI
import SwiftData
import UIKit

// MARK: - Minimal Liquid Glass Settings View
struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showDeleteAllDataConfirmation = false
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
                        Text(L10n.text("settings_title"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(L10n.text("settings_subtitle"))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .settingsCardEntrance(appeared: appeared, index: 0)

                    // Notifications
                    SettingsCard(
                        title: L10n.text("settings_section_notifications"),
                        icon: "bell.badge.fill",
                        color: AppTheme.coral
                    ) {
                        NotificationSettingsSection(profile: $viewModel.profile)
                    }
                    .settingsCardEntrance(appeared: appeared, index: 1)

                    // About
                    SettingsCard(
                        title: L10n.text("settings_about_title"),
                        icon: "info.circle.fill",
                        color: AppTheme.liquidAccent
                    ) {
                        SettingsInfoRow(icon: "doc.text", color: .white.opacity(0.4), text: L10n.text("settings_version") + " " + appVersion)
                        SettingsInfoRow(icon: "map.fill", color: AppTheme.sky, text: L10n.text("settings_data_apple_weather"))
                    }
                    .settingsCardEntrance(appeared: appeared, index: 2)

                    // Delete Data
                    LiquidGlassButton(L10n.text("settings_delete_all_data_title"), icon: "trash", style: .danger, haptic: .heavy) {
                        showDeleteAllDataConfirmation = true
                    }
                    .frame(maxWidth: .infinity)
                    .settingsCardEntrance(appeared: appeared, index: 3)

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
                .contentShape(Rectangle())
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
    }

    private func animateAppearance() {
        withAnimation(.easeOut(duration: 0.6)) {
            appeared = true
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
