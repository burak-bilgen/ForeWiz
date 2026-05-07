import SwiftUI

struct SettingsCard<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let content: Content

    init(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(alignment: .top, spacing: AppSpacing.small) {
                    Image(systemName: icon)
                        .font(.headline)
                        .frame(width: 32, height: 32)
                        .background(
                            AppTheme.softBubbleGradient(tint: AppTheme.accent),
                            in: RoundedRectangle(
                                cornerRadius: AppTheme.iconBubbleRadius,
                                style: .continuous
                            )
                        )
                        .foregroundStyle(AppTheme.accent)

                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(title)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppTheme.ink)
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                content
            }
        }
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                Text(value)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.small)
        .background(
            AppTheme.elevatedSurface.opacity(0.86),
            in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
        )
    }
}

struct AboutSection: View {
    var body: some View {
        SettingsCard(
            icon: "info.circle.fill",
            title: L10n.text("settings_about_title"),
            subtitle: L10n.text("settings_about_subtitle")
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Text(L10n.text("settings_version"))
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text(appVersion)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                HStack {
                    Text(L10n.text("settings_data_source"))
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text(L10n.text("settings_data_apple_weather"))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Text(L10n.text("settings_privacy_note"))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

struct SectionDivider: View {
    let label: String

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Rectangle()
                .fill(AppTheme.secondaryText.opacity(0.18))
                .frame(height: 1)

            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)

            Rectangle()
                .fill(AppTheme.secondaryText.opacity(0.18))
                .frame(height: 1)
        }
        .padding(.horizontal, AppSpacing.xSmall)
    }
}
