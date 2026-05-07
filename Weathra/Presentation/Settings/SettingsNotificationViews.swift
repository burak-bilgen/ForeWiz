import SwiftUI

struct NotificationSettingsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        Stepper(
            value: $profile.maximumDailyNotifications,
            in: 1...3
        ) {
            HStack {
                Text(L10n.text("settings_daily_limit"))
                Spacer()
                Text("\(profile.maximumDailyNotifications)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }

        QuietHoursPicker(quietHours: $profile.quietHours)

        ForEach($profile.notificationPreferences) { $preference in
            NotificationPreferenceToggle(preference: $preference)
        }
    }
}
