import SwiftUI

struct NotificationSettingsSection: View {
    @Binding var profile: UserComfortProfile

    var body: some View {
        LiquidGlassCard {
            HStack(spacing: 14) {
                GlassIcon(systemName: "bell.badge.fill", color: .liquidAccent)

                Text(L10n.text("settings_daily_limit"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)

                Spacer(minLength: 8)

                HStack(spacing: 0) {
                    GlassStepperButton(
                        systemName: "minus",
                        isActive: profile.maximumDailyNotifications > 1
                    ) {
                        if profile.maximumDailyNotifications > 1 {
                            profile.maximumDailyNotifications -= 1
                            Task { await HapticEngine.shared.selectionChanged() }
                        }
                    }

                    Text("\(profile.maximumDailyNotifications)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .frame(width: 28)

                    GlassStepperButton(
                        systemName: "plus",
                        isActive: profile.maximumDailyNotifications < 3
                    ) {
                        if profile.maximumDailyNotifications < 3 {
                            profile.maximumDailyNotifications += 1
                            Task { await HapticEngine.shared.selectionChanged() }
                        }
                    }
                }
                .glassEffect(in: Capsule())
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Glass Stepper Button

struct GlassStepperButton: View {
    let systemName: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isActive ? Color.liquidAccent : Color.white.opacity(0.2))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.fullTapArea)
    }
}

// MARK: - Glass Icon

struct GlassIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )

            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
        }
    }
}
