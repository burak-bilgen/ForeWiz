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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .frame(width: 32, height: 32)
                    .background(
                        .blue.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 28, height: 28)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(value)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            Color.gray.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n.text("settings_version"))
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(appVersion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(L10n.text("settings_data_source"))
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(L10n.text("settings_data_apple_weather"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(L10n.text("settings_privacy_note"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
        HStack(spacing: 12) {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .frame(height: 1)

            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Rectangle()
                .fill(.gray.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.horizontal, 12)
    }
}
