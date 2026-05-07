import SwiftUI

struct AdBannerView: View {
    let adUnitID: String?

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.xSmall) {
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.7))
                Text(L10n.text( "ad_label_text"))
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, AppSpacing.small)

            RoundedRectangle(cornerRadius: AppTheme.compactRadius)
                .fill(AppTheme.elevatedSurface.opacity(0.5))
                .frame(height: 60)
                .overlay {
                    Text(L10n.text( "ad_space_text"))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
                }
        }
        .padding(AppSpacing.small)
        .background(AppTheme.elevatedSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius))
        .overlay(alignment: .topTrailing) {
            Button(action: { /* Open paywall to remove ads */ }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(AppSpacing.xSmall)
        }
    }
}

#Preview {
    AdBannerView(adUnitID: nil)
}
