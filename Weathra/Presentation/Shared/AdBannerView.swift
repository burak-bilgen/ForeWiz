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

// MARK: - Free user banner

private struct AdSpaceView: View {
    let onRemoveAdsTapped: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.light()
            onRemoveAdsTapped()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(red: 1.0, green: 0.78, blue: 0.25).opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.25))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("ad_label_text"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                    Text(L10n.text("premium_upgrade"))
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.25))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.2))
            }
            .padding(14)
            .background(
                Color(red: 1.0, green: 0.78, blue: 0.25).opacity(0.07),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 1.0, green: 0.78, blue: 0.25).opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Premium user banner

private struct PremiumBannerView: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 0.35, green: 0.85, blue: 0.6).opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.6))
            }
            Text(L10n.text("settings_premium_active"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.6))
            Spacer()
        }
        .padding(14)
        .background(
            Color(red: 0.35, green: 0.85, blue: 0.6).opacity(0.07),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.35, green: 0.85, blue: 0.6).opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview("Free User") {
    ZStack {
        Color(red: 0.04, green: 0.08, blue: 0.18).ignoresSafeArea()
        AdBannerView(adUnitID: nil, isPremium: false, onRemoveAdsTapped: {})
            .padding()
    }
}

#Preview("Premium User") {
    ZStack {
        Color(red: 0.04, green: 0.08, blue: 0.18).ignoresSafeArea()
        AdBannerView(adUnitID: nil, isPremium: true, onRemoveAdsTapped: {})
            .padding()
    }
}
