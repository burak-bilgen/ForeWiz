import SwiftUI

struct NotificationSettingsSection: View {
    @Binding var profile: UserComfortProfile

    private let notifColor = Color(red: 1.0, green: 0.45, blue: 0.45)

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(notifColor.opacity(0.16))
                    .frame(width: 34, height: 34)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(notifColor)
            }
            Text(L10n.text("settings_daily_limit"))
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Spacer(minLength: 8)
            HStack(spacing: 0) {
                Button {
                    if profile.maximumDailyNotifications > 1 {
                        profile.maximumDailyNotifications -= 1
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(profile.maximumDailyNotifications > 1 ? notifColor : Color.white.opacity(0.2))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)

                Text("\(profile.maximumDailyNotifications)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .frame(width: 28)

                Button {
                    if profile.maximumDailyNotifications < 3 {
                        profile.maximumDailyNotifications += 1
                        HapticManager.selection()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(profile.maximumDailyNotifications < 3 ? notifColor : Color.white.opacity(0.2))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .glassEffect(.regular, in: Capsule())
        }
        .padding(.vertical, 8)
    }
}
