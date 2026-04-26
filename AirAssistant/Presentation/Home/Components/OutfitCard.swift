import SwiftUI

struct OutfitCard: View {
    let outfit: OutfitRecommendation

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Label("Kıyafet önerisi", systemImage: "tshirt.fill")
                    .font(AppTypography.headline)
                Text(outfit.title)
                    .font(AppTypography.body)

                if !outfit.accessories.isEmpty {
                    Text(outfit.accessories.joined(separator: " • "))
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                if let warning = outfit.warning {
                    Text(warning)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.warning)
                        .padding(.top, AppSpacing.xSmall)
                }
            }
        }
    }
}
