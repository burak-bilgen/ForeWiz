import SwiftUI

struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 32, height: 32)
                .background(
                    AppTheme.softBubbleGradient(tint: AppTheme.accent),
                    in: RoundedRectangle(cornerRadius: AppTheme.iconBubbleRadius, style: .continuous)
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
        HStack(alignment: .center, spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .frame(width: 28, height: 28)
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xSmall) {
                    Text(title)
                        .font(AppTypography.caption.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    if isRequired {
                        Text(L10n.text("permission_required"))
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.warning)
                    }
                    Text(statusText)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Text(message)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppSpacing.small)

            Button(action: action) {
                Text(actionTitle)
                    .font(AppTypography.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, AppSpacing.xSmall)
                    .background(AppTheme.accent.opacity(0.14), in: Capsule())
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.small)
        .background(
            AppTheme.elevatedSurface.opacity(0.86),
            in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
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
                .font(AppTypography.caption.weight(.semibold))
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.xSmall)
                .background(
                    isSelected ? AppTheme.accent.opacity(0.16) : AppTheme.elevatedSurface,
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.ink)
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
