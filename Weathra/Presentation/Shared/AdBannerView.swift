import SwiftUI

struct AdBannerView: View {
    let adUnitID: String?
    let isPremium: Bool
    let onRemoveAdsTapped: () -> Void

    var body: some View {
        if isPremium {
            PremiumBannerView()
        } else {
            AdSpaceView(onRemoveAdsTapped: onRemoveAdsTapped)
        }
    }
}

private struct AdSpaceView: View {
    let onRemoveAdsTapped: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary.opacity(0.7))
                Text(L10n.text("ad_label_text"))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, 12)

            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.1))
                .frame(height: 60)
                .overlay {
                    Text(L10n.text("ad_space_text"))
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
        }
        .padding(12)
        .background(
            .gray.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(alignment: .topTrailing) {
            Button(action: {
                HapticManager.light()
                onRemoveAdsTapped()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(8)
        }
    }
}

private struct PremiumBannerView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.yellow)

            Text(L10n.text("settings_premium_active"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(12)
        .background(
            .yellow.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

#Preview("Free User") {
    AdBannerView(adUnitID: nil, isPremium: false, onRemoveAdsTapped: {})
}

#Preview("Premium User") {
    AdBannerView(adUnitID: nil, isPremium: true, onRemoveAdsTapped: {})
}
