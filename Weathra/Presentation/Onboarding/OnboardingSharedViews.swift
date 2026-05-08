import SwiftUI

struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 32, height: 32)
                .background(
                    .blue.opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct CompactPermissionRow: View {
    let icon: String
    let title: String
    let message: String
    let statusText: String
    let isRequired: Bool
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .frame(width: 28, height: 28)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                    if isRequired {
                        Text(L10n.text("permission_required"))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                    Text(statusText)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(action: action) {
                Text(actionTitle)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.14), in: Capsule())
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(
            .gray.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

struct ActivityChip: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(activity.localizedTitle, systemImage: iconName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    isSelected ? .blue.opacity(0.16) : .gray.opacity(0.1),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .blue : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var iconName: String {
        switch activity {
        case .running:
            "figure.run"
        case .walking:
            "figure.walk"
        case .cycling:
            "bicycle"
        case .goingOutside:
            "sun.max.fill"
        }
    }
}
