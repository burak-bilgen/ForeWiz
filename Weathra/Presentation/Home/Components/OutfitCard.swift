import SwiftUI

struct OutfitCard: View {
    let outfit: OutfitRecommendation

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label(L10n.text("notification_outfit"), systemImage: "tshirt.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)

                Text(outfit.title)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if !outfit.items.isEmpty {
                    FlowLayout(spacing: AppSpacing.small) {
                        ForEach(outfit.items, id: \.self) { item in
                            OutfitChip(text: item)
                        }
                    }
                }

                if !outfit.accessories.isEmpty {
                    InsightRow(
                        icon: "sparkles",
                        title: L10n.text("outfit_accessories"),
                        value: outfit.accessories.joined(separator: " • "),
                        tint: AppTheme.teal
                    )
                }

                if let warning = outfit.warning {
                    InsightRow(
                        icon: "exclamationmark.triangle.fill",
                        title: L10n.text("outfit_warning"),
                        value: warning,
                        tint: AppTheme.warning
                    )
                }
            }
        }
    }
}

private struct OutfitChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTypography.caption)
            .lineLimit(1)
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.elevatedSurface, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(AppTheme.separator.opacity(0.4), lineWidth: 0.5)
            }
    }
}
