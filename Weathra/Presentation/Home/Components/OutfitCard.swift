import SwiftUI

struct OutfitCard: View {
    let outfit: OutfitRecommendation

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label("Kıyafet önerisi", systemImage: "tshirt.fill")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)
                Text(outfit.title)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if outfit.items.isEmpty == false {
                    FlowLayout(spacing: AppSpacing.small) {
                        ForEach(outfit.items, id: \.self) { item in
                            Text(item)
                                .font(AppTypography.caption)
                                .lineLimit(1)
                                .foregroundStyle(AppTheme.ink)
                                .padding(.horizontal, AppSpacing.small)
                                .padding(.vertical, AppSpacing.xSmall)
                                .background(AppTheme.elevatedSurface, in: Capsule())
                        }
                    }
                }

                if !outfit.accessories.isEmpty {
                    InsightRow(
                        icon: "sparkles",
                        title: "Yanına iyi gider",
                        value: outfit.accessories.joined(separator: " • "),
                        tint: AppTheme.teal
                    )
                }

                if let warning = outfit.warning {
                    InsightRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Hava notu",
                        value: warning,
                        tint: AppTheme.warning
                    )
                }
            }
        }
    }
}
