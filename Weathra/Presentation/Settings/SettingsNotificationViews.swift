import SwiftUI

struct NotificationSettingsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        SettingsCard(
            icon: "bell.badge.fill",
            title: L10n.text("settings_notifications_title"),
            subtitle: L10n.text("settings_notifications_subtitle")
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Stepper(
                    L10n.text("settings_daily_limit") + " \(profile.maximumDailyNotifications)",
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
